# Benchmark

We need to setup new rails app with commands:

```bash
bin/rails new dl --main -d postgresql
bundle add dynamic_links
bin/rails dynamic_links:install:migrations
bin/rails db:create
bin/rails db:migrate
```

After that we can do benchmark

## Benchmark `DynamicLinks::ShortenedUrl.find_or_create!`
### Benchmark Code

create `script/benchmarks/dynamic_links_shortened_url_empty.rb`
```ruby
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../../config/environment.rb'

DynamicLinks::ShortenedUrl.all.delete_all
DynamicLinks::Client.all.delete_all

@client_v1 = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 1', api_key: 'create_or_find_v1', hostname: 'bm-1.com', scheme: 'http')
@client_v2 = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 2', api_key: 'create_or_find_v2', hostname: 'bm-2.com', scheme: 'http')

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("DynamicLinks::ShortenedUrlV1.find_or_create! - 1st run") do |times|
    DynamicLinks::ShortenedUrlV1.find_or_create!(@client_v1, "u2_#{rand.ceil(2) + rand.ceil(2)}", "https://bm-1.com/#{rand.ceil(2) + rand.ceil(2)}")
  end

  x.report("DynamicLinks::ShortenedUrlV2.find_or_create! - 1st run") do |times|
    DynamicLinks::ShortenedUrlV2.find_or_create!(@client_v2, "u_#{rand.ceil(2) + rand.ceil(2)}", "https://bm-2.com/#{rand.ceil(2) + rand.ceil(2)}")
  end

  x.compare!
end
```

create `script/benchmarks/dynamic_links_shortened_url_exist.rb`
```ruby
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../../config/environment.rb'

@client_v1 = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 1', api_key: 'create_or_find_v1', hostname: 'bm-1.com', scheme: 'http')
@client_v2 = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 2', api_key: 'create_or_find_v2', hostname: 'bm-2.com', scheme: 'http')

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("DynamicLinks::ShortenedUrlV1.find_or_create! - 2nd run") do |times|
    DynamicLinks::ShortenedUrlV1.find_or_create!(@client_v1, "u2_#{rand.ceil(2) + rand.ceil(2)}", "https://bm-1.com/#{rand.ceil(2) + rand.ceil(2)}")
  end

  x.report("DynamicLinks::ShortenedUrlV2.find_or_create! - 2nd run") do |times|
    DynamicLinks::ShortenedUrlV2.find_or_create!(@client_v2, "u_#{rand.ceil(2) + rand.ceil(2)}", "https://bm-2.com/#{rand.ceil(2) + rand.ceil(2)}")
  end

  x.compare!
end

```

### Run Benchmark
```bash
ruby script/benchmarks/dynamic_links_shortened_url_empty.rb
ruby script/benchmarks/dynamic_links_shortened_url_exist.rb
```

### Benchmark Result
```bash
Warming up --------------------------------------
DynamicLinks::ShortenedUrlV1.find_or_create! - 1st run
                       370.021M i/100ms
DynamicLinks::ShortenedUrlV2.find_or_create! - 1st run
                         6.997B i/100ms
Calculating -------------------------------------
DynamicLinks::ShortenedUrlV1.find_or_create! - 1st run
                         90.448B (±37.3%) i/s -    346.710B in   5.001228s
DynamicLinks::ShortenedUrlV2.find_or_create! - 1st run
                          1.745T (±35.3%) i/s -      6.808T in   4.998993s

Comparison:
DynamicLinks::ShortenedUrlV2.find_or_create! - 1st run: 1745265993412.1 i/s
DynamicLinks::ShortenedUrlV1.find_or_create! - 1st run: 90447630382.2 i/s - 19.30x  slower


Warming up --------------------------------------
DynamicLinks::ShortenedUrlV1.find_or_create! - 2nd run
                        23.211B i/100ms
DynamicLinks::ShortenedUrlV2.find_or_create! - 2nd run
                        34.098B i/100ms
Calculating -------------------------------------
DynamicLinks::ShortenedUrlV1.find_or_create! - 2nd run
                          6.215T (±25.3%) i/s -     27.784T in   4.999502s
DynamicLinks::ShortenedUrlV2.find_or_create! - 2nd run
                          9.032T (±23.1%) i/s -     41.395T in   4.998096s

Comparison:
DynamicLinks::ShortenedUrlV2.find_or_create! - 2nd run: 9032016948137.5 i/s
DynamicLinks::ShortenedUrlV1.find_or_create! - 2nd run: 6214621375219.4 i/s - same-ish: difference falls within error
```

## `DynamicLinks.shorten_url` Benchmark
### Benchmark Code
create `script/benchmarks/dynamic_links_client_find_or_create_by_empty.rb`
```ruby
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../../config/environment.rb'

DynamicLinks::ShortenedUrl.all.delete_all
DynamicLinks::Client.all.delete_all

@client_v1 = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 1', api_key: 'benchmark-v1', hostname: 'benchmark-v1.com', scheme: 'http')
@client_v2 = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 2', api_key: 'benchmark-v2', hostname: 'benchmark-v2.com', scheme: 'http')

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("DynamicLinks.shorten_url_v1 - 1st run") do |times|
    DynamicLinks.shorten_url_v1("https://benchmark-v1.com/#{rand + rand}", @client_v1)
  end

  x.report("DynamicLinks.shorten_url_v2 - 1st run") do |times|
    DynamicLinks.shorten_url_v2("https://benchmark-v2.com/#{rand + rand}", @client_v2)
  end

  x.compare!

end
```

create `script/benchmarks/dynamic_links_client_find_or_create_by_exist.rb`
```ruby
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../../config/environment.rb'

@client_v1 = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 1', api_key: 'benchmark-v1', hostname: 'benchmark-v1.com', scheme: 'http')
@client_v2 = DynamicLinks::Client.find_or_create_by!(name: 'Benchmark Client 2', api_key: 'benchmark-v2', hostname: 'benchmark-v2.com', scheme: 'http')

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("DynamicLinks.shorten_url_v1 - 2nd run") do |times|
    DynamicLinks.shorten_url_v1("https://benchmark-v1.com/#{rand + rand}", @client_v1)
  end

  x.report("DynamicLinks.shorten_url_v2 - 2nd run") do |times|
    DynamicLinks.shorten_url_v2("https://benchmark-v2.com/#{rand + rand}", @client_v2)
  end

  x.compare!

end
```

### Run Benchmark
```bash
ruby script/benchmarks/dynamic_links_client_find_or_create_by_empty.rb
ruby script/benchmarks/dynamic_links_client_find_or_create_by_exist.rb
```

### Result
```bash
Warming up --------------------------------------
DynamicLinks.shorten_url_v1 - 1st run
                       169.236M i/100ms
DynamicLinks.shorten_url_v2 - 1st run
                        10.103B i/100ms
Calculating -------------------------------------
DynamicLinks.shorten_url_v1 - 1st run
                         13.464B (±16.2%) i/s -     64.817B in   5.009564s
DynamicLinks.shorten_url_v2 - 1st run
                        812.731B (±12.9%) i/s -      3.991T in   5.002609s

Comparison:
DynamicLinks.shorten_url_v2 - 1st run: 812731352398.1 i/s
DynamicLinks.shorten_url_v1 - 1st run: 13464249938.5 i/s - 60.36x  slower



Warming up --------------------------------------
DynamicLinks.shorten_url_v1 - 2nd run
                        70.811M i/100ms
DynamicLinks.shorten_url_v2 - 2nd run
                         8.867B i/100ms
Calculating -------------------------------------
DynamicLinks.shorten_url_v1 - 2nd run
                          5.467B (±18.1%) i/s -     25.209B in   5.011350s
DynamicLinks.shorten_url_v2 - 2nd run
                        692.582B (±13.5%) i/s -      3.396T in   5.001811s

Comparison:
DynamicLinks.shorten_url_v2 - 2nd run: 692582037559.2 i/s
DynamicLinks.shorten_url_v1 - 2nd run: 5466954043.4 i/s - 126.69x  slower
```