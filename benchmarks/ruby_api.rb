require 'benchmark/ips'
require_relative '../test/dummy/config/environment.rb'

DynamicLinks.configure do |config|
  config.shortening_strategy = :md5
  config.cache_store_config = { type: :redis, redis_config: { host: 'redis' } }
end

# Dummy client setup
client = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client', api_key: 'benchmark_key', hostname: 'example.com', scheme: 'http')

DynamicLinks::ShortenedUrl.where(client: client).delete_all

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("sync shorten_url") do |times|
    DynamicLinks.shorten_url("https://example.com/#{times}", client, async: false)
  end

  x.report("async shorten_url") do |times|
    DynamicLinks.shorten_url("https://example-async.com/#{times}", client, async: true)
  end

  x.compare!
end

# Results:
# ruby 3.2.2 (2023-03-30 revision e51014f9c0) +YJIT [x86_64-linux]
# Warming up --------------------------------------
#     sync shorten_url    32.036B i/100ms
#    async shorten_url    186.494B i/100ms
# Calculating -------------------------------------
#     sync shorten_url     68.100T (±17.2%) i/s -    325.931T in   4.992942s
#    async shorten_url    411.674T (±19.4%) i/s -      1.841Q in   4.992430s

# Comparison:
#    async shorten_url: 411673657787738.8 i/s
#     sync shorten_url: 68100041231802.3 i/s - 6.05x  slower
