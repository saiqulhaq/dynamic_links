module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class Shortener
    # @param client [Client] the client that owns the url
    # @param url [String] the url to be shortened
    # @return [String] the shortened url
    def shorten(client, url)
      short_url = strategy.shorten(url)

      if strategy.always_growing?
        storage.create!(client: client, url: url, short_url: short_url)
      else
        storage.find_or_create(client, short_url, url)
      end
      URI::Generic.build({scheme: client.scheme, host: client.hostname, path: "/#{short_url}"}).to_s
    end

    def shorten_async(client, url)
      lock_key = locker.generate_key(client, url)

      locker.lock_if_absent(lock_key) do
        short_url = strategy.shorten(url)
        content = {
          url: url,
          short_url: short_url
        }

        async_worker.perform_later(client, url, short_url, lock_key)
      end
    end

    # @api private
    def locker(klass = DynamicLinks::Async::Locker)
      @locker ||= klass.new
    end

    # @api private
    def strategy(strategy_key = DynamicLinks.configuration.shortening_strategy)
      @strategy ||= StrategyFactory.get_strategy(strategy_key)
    end

    # @api private
    def storage(model = ShortenedUrl)
      @shortened_url_model ||= model
    end

    # @api private
    def async_worker(klass = ShortenUrlJob)
      @async_worker ||= klass
    end
  end
end
