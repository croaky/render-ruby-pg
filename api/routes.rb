require_relative "../lib/x"

X::API.routes do |db|
  get "/health" do |req, resp|
    db.exec "SELECT 1"
    [
      200,
      resp.headers.merge("Cache-Control" => "max-age=3600"),
      {status: "ok"}.to_json
    ]
  end
end
