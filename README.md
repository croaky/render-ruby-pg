# X

A lightweight JSON HTTP API with Ruby and Postgres.

Deploy with Render at <https://dashboard.render.com/blueprints>.
Click "New Blueprint Instance".
Enter this repo's URL.

## Local development

Install Ruby 3 and Postgres 14.

Create development database:

```
createdb x_dev --owner=postgres
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

See `api/routes.rb`:

```ruby
X::API.routes do |db|
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
