# frozen_string_literal: true

# Safelist trusted IPs loaded from RACK_ATTACK_TRUSTED_IPS (comma-separated).
# These addresses bypass all throttle checks — intended for internal
# infrastructure egress IPs (e.g. Kubernetes NAT gateway addresses).
trusted_ips = ENV.fetch('RACK_ATTACK_TRUSTED_IPS', '').split(',').map(&:strip).reject(&:empty?)
trusted_ips.each do |ip|
  Rack::Attack.safelist("trusted/#{ip}") { |req| req.ip == ip }
end

# Default throttle: 60 requests per second per IP for all other clients.
Rack::Attack.throttle('req/ip', limit: 60, period: 1) do |req|
  req.ip unless trusted_ips.include?(req.ip)
end

# Return 429 JSON on throttle instead of the default plain-text response.
Rack::Attack.throttled_responder = lambda do |_req|
  [429, { 'Content-Type' => 'application/json' }, ['{"error":"Too Many Requests"}']]
end
