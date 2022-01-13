#!/usr/bin/env ruby

require "date"
require_relative "lib/x"

usage = <<~EOF
  usage:
    x build              install deps
    x api ls             print API routes
    x api start          run HTTP server
    x db gen NAME        generate new database migration of NAME
    x db migrate         apply database migrations
    x worker ls          print worker names
    x worker start NAME  run worker of NAME
EOF

if ARGV.length < 1
  puts usage
  exit 1
end

if ARGV[0] == "build"
  system("bundle install", out: $stdout)
  exit 0
end

if ARGV[0] == "api"
  cmds = %w[ls start]
  unless cmds.include?(ARGV[1])
    puts usage
    exit 1
  end

  require_relative "api/routes"

  if ARGV[1] == "ls"
    puts "TODO"
    exit 0
  end

  if ARGV[1] == "start"
    X::API.serve
    exit 0
  end
end

if ARGV[0] == "worker"
  cmds = %w[ls start]
  unless cmds.include?(ARGV[1])
    puts usage
    exit 1
  end

  workers = Dir.glob("worker/*.rb").map do |fpath|
    fpath.split("/")[1].split(".rb")[0]
  end

  if ARGV[1] == "ls"
    puts workers
    exit 0
  end

  if ARGV[1] == "start"
    name = ARGV[2]

    unless workers.include?(name)
      puts "err: valid worker names are:"
      puts workers
      exit 1
    end

    system("bundle exec ruby worker/#{name}.rb", out: $stdout)
    exit 0
  end
end

if ARGV[0] == "db"
  cmds = %w[gen migrate]
  unless cmds.include?(ARGV[1])
    puts usage
    exit 1
  end

  if ARGV[1] == "gen"
    if ARGV.length < 2
      puts usage
      exit 1
    end

    sql = <<~SQL
      BEGIN;
      -- TODO
      COMMIT;
    SQL

    version = Time.now.utc.strftime("%Y%m%d%H%M%S")
    File.write("db/migrate/#{version}_#{ARGV[2]}.sql", sql)
  end

  if ARGV[1] == "migrate"
    X::Database.migrate
  end

  exit 0
end

puts usage
exit 1
