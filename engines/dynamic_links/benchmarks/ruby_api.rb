require 'benchmark/ips'
require_relative '../test/dummy/config/environment'

DynamicLinks.configure do |config|
  config.shortening_strategy = :md5
end

# Dummy client setup
client = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client', api_key: 'benchmark_key',
                                                 hostname: 'example.com', scheme: 'http')

DynamicLinks::ShortenedUrl.where(client: client).delete_all

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('sync shorten_url') do |times|
    DynamicLinks.shorten_url("https://example.com/#{times}", client, async: false)
  end

  x.report('async shorten_url') do |times|
    DynamicLinks.shorten_url("https://example-async.com/#{times}", client, async: true)
  end

  x.compare!
end

# Results: 2023-01-05
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

# Results: 2023-01-06
# ruby 3.2.2 (2023-03-30 revision e51014f9c0) +YJIT [x86_64-linux]
# Warming up --------------------------------------
#     sync shorten_url    29.439B i/100ms
#    async shorten_url2024-01-06T11:30:31.937Z pid=6316 tid=3uo INFO: Sidekiq 7.2.0 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>"redis://redis:6379/2"}
#    216.882B i/100ms
# Calculating -------------------------------------
#     sync shorten_url     67.021T (±21.4%) i/s -    313.206T in   4.993776s
#    async shorten_url      3.887Q (±21.7%) i/s -     17.554Q in   4.958253s
# Comparison:
#    async shorten_url: 3887497582634705.5 i/s
#     sync shorten_url: 67020687656060.7 i/s - 58.00x  slower

# When the cache is exist
# ruby 3.2.2 (2023-03-30 revision e51014f9c0) +YJIT [x86_64-linux]
# Warming up --------------------------------------
#     sync shorten_url    21.002B i/100ms
#    async shorten_url2024-01-06T11:32:12.036Z pid=6347 tid=3xj INFO: Sidekiq 7.2.0 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>"redis://redis:6379/2"}
#    830.542B i/100ms
# Calculating -------------------------------------
#     sync shorten_url     49.498T (±20.3%) i/s -    232.909T in   4.993091s
#    async shorten_url     15.310Q (±20.2%) i/s -     69.875Q in   4.957633s
# Comparison:
#    async shorten_url: 15309572098986642.0 i/s
#     sync shorten_url: 49497616265721.5 i/s - 309.30x  slower
