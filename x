#!/usr/bin/env ruby

require "date"

usage = <<~EOF
  usage:
    x build        run HTTP server
    x start        run HTTP server
    x db gen NAME  generate new database migration
    x db migrate   apply all database migrations
EOF

if ARGV.length < 1
  puts usage
  exit 1
end

if ARGV[0] == "build"
  system("bundle install", out: $stdout)
  require_relative "lib/x"
  X::Env.load(root_dir: Dir.pwd)
  X::Database.migrate
  exit 0
end

if ARGV[0] == "start"
  system("bundle exec ruby api/routes.rb", out: $stdout)
  exit 0
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
    require_relative "lib/x"
    X::Env.load(root_dir: Dir.pwd)
    X::Database.migrate
  end

  exit 0
end

puts usage
exit 1
