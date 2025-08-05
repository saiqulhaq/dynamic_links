# Define trusted IP addresses with higher limits from environment variable
TRUSTED_IPS = ENV.fetch('RACK_ATTACK_TRUSTED_IPS', '').split(',').map(&:strip).freeze

# Throttle requests for trusted IPs - 1000 requests per second
Rack::Attack.throttle('requests by trusted ip', limit: 1000, period: 1) do |request|
  if request.path == '/v1/shortLinks' && request.post? && TRUSTED_IPS.any? && TRUSTED_IPS.include?(request.ip)
    request.ip
  end
end

# Throttle requests to 5 requests per 2 seconds by IP (for non-trusted IPs)
Rack::Attack.throttle('requests by ip', limit: 5, period: 2) do |request|
  if request.path == '/v1/shortLinks' && request.post? && (!TRUSTED_IPS.any? || !TRUSTED_IPS.include?(request.ip))
    request.ip
  end
end
