#!/usr/bin/env ruby

require "date"
require_relative "lib/x"

usage = <<~EOF
  usage:
    x api          run HTTP server
    x db gen NAME  generate new database migration
    x db migrate   apply all database migrations
EOF

if ARGV.length < 1
  puts usage
  exit 1
end

if ARGV[0] == "api"
  `bundle exec ruby api/routes.rb`
  exit 0
end

if ARGV[0] == "init"
  # install Ruby deps
  `bundle install`

  # create Postgres dbs
  `createdb render_dev`
  `createdb render_test`

  # migrate dev db
  X::Env.load(root_dir: Dir.pwd)
  X::Database.migrate
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
    X::Env.load(root_dir: Dir.pwd)
    X::Database.migrate
  end

  exit 0
end

puts usage
exit 1
