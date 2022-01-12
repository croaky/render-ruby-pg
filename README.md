# X

A lightweight JSON HTTP API with Ruby and Postgres
meant to be deployed to <https://render.com>.

## Develop

Install Ruby 3+ and Postgres 13+.

Create development database:

```
createdb render_dev
```

Build project:

```
./x build
```

See project structure:

```
.
├── Gemfile
├── Gemfile.lock
├── README.md
├── api
│   └── routes.rb
├── db
│   ├── migrate
│   │   └── 20220111234433_init.sql
│   └── schema.sql
├── env
│   ├── dev
│   └── test
├── lib
│   └── x.rb
└── x
```

See `api.rb`:

```ruby
require "x"

X::Env.load(root_dir: Dir.pwd)

X::API.serve do |db|
  get "/health" do |req, resp|
    db.exec "SELECT 1"
    [
      200,
      resp.headers.merge("Cache-Control" => "max-age=3600"),
      {"status": "ok"}.to_json
    ]
  end
end
```

Start the web server:

```
./x start
```

Open <http://localhost:2000/health>.

## Deploy

Create a new web service in Render at
<https://dashboard.render.com/web/new>.

Set GitHub URL to this repo
<https://github.com/croaky/render-ruby-pg>.

Set "Build Command" to `./x build`.

Set "Start Command" to `./x start`.
