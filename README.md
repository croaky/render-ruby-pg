# X

A lightweight JSON HTTP API with Ruby and Postgres
meant to be deployed to <https://render.com>.

## Develop

Install Ruby 3 and Postgres 14.

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

Go to Render Blueprints page at
<https://dashboard.render.com/blueprints>.
Click "New Blueprint Instance".
Enter this repo's URL.
