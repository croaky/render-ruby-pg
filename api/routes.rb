require_relative "../lib/x"

X::Env.load(root_dir: Dir.pwd)

X::API.serve do |db|
  get "/health" do |req, resp|
    db.exec "SELECT 1"
    [
      200,
      resp.headers.merge("Cache-Control" => "max-age=3600"),
      {status: "ok"}.to_json
    ]
  end
end