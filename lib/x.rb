require "rubygems"
require "bundler"

Bundler.setup(:default)

require "async"
require "async/http/endpoint"
require "async/http/server"
require "connection_pool"
require "json"
require "pg"

env_file = "#{Dir.pwd}/env/#{ENV.fetch("APP_ENV", "dev")}"

if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    key, val = line.split("=", 2)
    ENV[key] = val.chomp
  end
end

module X
  class API
    class << self
      attr_accessor :router

      def routes(&block)
        db = X::Database.new(
          ENV.fetch("DATABASE_URL"),
          ENV.fetch("DATABASE_POOL_SIZE")
        )
        self.router = X::Router.new
        router.instance_exec(db, &block)
      end

      def serve
        if router.nil?
          raise StandardError, "Use API.routes to initialize router."
        end

        server = Async::HTTP::Server.new(
          router,
          Async::HTTP::Endpoint.parse("http://0.0.0.0:#{ENV.fetch("PORT")}")
        )

        Async do |task|
          task.async do
            server.run
          end
        end
      end
    end
  end

  class Database
    def initialize(url, pool_size)
      @pool = ConnectionPool.new(size: pool_size, timeout: 5) {
        conn = PG.connect(url)
        conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn)
        conn
      }
    end

    def exec(sql, params = nil)
      @pool.with do |conn|
        if params.nil?
          conn.exec(sql)
        else
          conn.exec_params(sql, params)
        end
      end
    end

    def self.migrate
      db = new(
        ENV.fetch("DATABASE_URL"),
        ENV.fetch("DATABASE_POOL_SIZE")
      )
      ready = db.exec(<<~SQL).first["exists"]
        SELECT EXISTS (
          SELECT FROM information_schema.tables
          WHERE table_schema = 'public' AND table_name = 'migrations'
        )
      SQL
      versions =
        if ready
          db.exec(<<~SQL).to_a.map { |m| m["version"] }
            SELECT version
            FROM migrations
            ORDER BY version DESC
          SQL
        else
          []
        end
      Dir.glob("db/migrate/**.sql").each do |fpath|
        v = fpath.split("/")[-1].split(".")[0]
        if versions.include?(v)
          next
        end
        db.exec(File.read(fpath))
        db.exec(<<~SQL, [v])
          INSERT INTO migrations (version, applied_at)
          VALUES ($1, now())
        SQL
      end
      if ENV.fetch("APP_ENV") == "dev"
        system("pg_dump --schema-only x_dev > db/schema.sql", out: $stdout)
      end
    end
  end

  class Request
    attr_accessor :headers, :body

    def initialize(headers, body)
      @headers = headers || {}
      @body = body || {}
    end
  end

  class Response
    attr_accessor :status, :headers, :body

    def initialize
      @headers = {
        "Accept" => "application/json",
        "Access-Control-Allow-Methods" => "OPTIONS,GET,POST",
        "Content-Type" => "application/json"
      }
    end
  end

  class Router
    def initialize
      @routes = {}
    end

    def get(path, &handler)
      @routes[path] = handler
    end

    def post(path, &handler)
      @routes[path] = handler
    end

    def call(req)
      t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      resp = X::Response.new

      if !["OPTIONS", "GET", "POST"].include?(req.method)
        resp.status = 405
        resp.body = %({"err": "#{req.method} not supported. Try OPTIONS, GET, or POST."})
      end

      if req.method == "OPTIONS"
        # Cache pre-flight requests for 2 hours
        # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age
        resp.headers = resp.headers.merge("Access-Control-Max-Age" => "7200")
        resp.status = 204
      end

      if req.method == "GET" || req.method == "POST"
        handler = @routes[req.path]

        if handler.nil?
          resp.status = 404
          resp.body = %({"err": "Route not found."})
        end
      end

      if req.method == "POST"
        if resp.status.nil? && req.body && req.body.length > 0
          begin
            parsed_body = JSON.parse(req.body.read)
          rescue
            resp.status = 400
            resp.body = %({err: "JSON request body is invalid."})
          end
        end
      end

      if resp.status.nil?
        resp.status, resp.headers, resp.body = catch(:halt) {
          throw :halt, handler.call(X::Request.new(req.headers, parsed_body), resp)
        }
      end

      elapsed = "%.3f" % (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t)
      puts "#{elapsed}s #{resp.status} #{req.method} #{req.path}"
      Protocol::HTTP::Response[resp.status, resp.headers, [resp.body]]
    rescue => err
      if err.is_a?(ConnectionPool::TimeoutError)
        resp.status = 504
        resp.body = %({err: "timeout"})
      else
        resp.status = 500
        resp.body = %({err: "something went wrong"})
      end

      elapsed = "%.3f" % (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t)
      puts "#{elapsed}s api #{resp.status} #{req.method} #{req.path}"
      Protocol::HTTP::Response[resp.status, resp.headers, [resp.body]]
    end
  end
end
