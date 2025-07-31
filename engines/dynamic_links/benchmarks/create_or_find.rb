# frozen_string_literal: true

# @author Saiqul Haq <saiqulhaq@gmail.com>

require 'benchmark/ips'
require_relative '../test/dummy/config/environment'

client = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 2', api_key: 'create_or_find',
                                                 hostname: 'example2.com', scheme: 'http')

DynamicLinks::ShortenedUrl.where(client: client).delete_all

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('version 1') do |times|
    DynamicLinks::ShortenedUrl.create_or_find_v1(client, "u2_#{times}", "https://e.com/#{times}")
  end

  x.report('version 2') do |times|
    DynamicLinks::ShortenedUrl.create_or_find_v2(client, "u_#{times}", "https://e.com/#{times}")
  end

  x.compare!
end

# result 1st run, when the record doesn't exist
# ruby 3.2.2 (2023-03-30 revision e51014f9c0) +YJIT [x86_64-linux]
# Warming up --------------------------------------
#            version 1    31.375B i/100ms
#            version 2    41.160B i/100ms
# Calculating -------------------------------------
#            version 1     77.901T (±22.4%) i/s -    361.498T in   4.992731s
#            version 2     28.375T (±17.9%) i/s -    136.735T in   4.997445s
# Comparison:
#            version 1: 77901187338263.5 i/s
#            version 2: 28375221927813.5 i/s - 2.75x  slower

# result 2nd run, when the record already exists
# ruby 3.2.2 (2023-03-30 revision e51014f9c0) +YJIT [x86_64-linux]
# Warming up --------------------------------------
#            version 1   170.252B i/100ms
#            version 2    75.387B i/100ms
# Calculating -------------------------------------
#            version 1    431.022T (±21.6%) i/s -      2.013Q in   4.993299s
#            version 2     52.222T (±17.7%) i/s -    252.019T in   4.999358s
# Comparison:
#            version 1: 431021525910322.2 i/s
#            version 2: 52221834807549.5 i/s - 8.25x  slower

# V1 and V2 code
# def self.create_or_find_v1(client, short_url, url)
#   record = find_or_initialize_by(client: client, short_url: short_url)
#   record.url = url if record.new_record?
#   record.save!
# end

# def self.create_or_find_v2(client, short_url, url)
#   record = ShortenedUrl.new(client: client, short_url: short_url, url: url)
#   record.save!
# rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
#   find_by!(client: client, short_url: short_url)
# end
