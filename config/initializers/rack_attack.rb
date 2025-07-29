# Throttle requests to 5 requests per 2 seconds by IP
Rack::Attack.throttle("requests by ip", limit: 5, period: 2) do |request|
  if request.path == "/v1/shortLinks" && request.post?
    request.ip
  end
end
