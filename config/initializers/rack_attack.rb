Rack::Attack.throttle("login/ip", limit: 5, period: 60) do |req|
  req.ip if req.path == "/api/v1/auth/login" && req.post?
end

Rack::Attack.throttle("register/ip", limit: 3, period: 3600) do |req|
  req.ip if req.path == "/api/v1/auth/register" && req.post?
end

Rack::Attack.throttled_responder = lambda do |_req|
  [429, { "Content-Type" => "application/json" }, ['{"error":"Muitas tentativas. Tente novamente mais tarde."}']]
end
