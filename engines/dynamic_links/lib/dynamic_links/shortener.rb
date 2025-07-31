module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class Shortener
    attr_reader :locker, :strategy, :storage, :async_worker

    def initialize(locker: DynamicLinks::Async::Locker.new,
                   strategy: StrategyFactory.get_strategy(DynamicLinks.configuration.shortening_strategy),
                   storage: ShortenedUrl,
                   async_worker: ShortenUrlJob)
      @locker = locker
      @strategy = strategy
      @storage = storage
      @async_worker = async_worker
    end

    # @param client [Client] the client that owns the url
    # @param url [String] the url to be shortened
    # @return [String] the shortened url
    def shorten(client, url)
      short_url = strategy.shorten(url)

      if strategy.always_growing?
        storage.create!(client: client, url: url, short_url: short_url)
      else
        storage.find_or_create!(client, short_url, url)
      end
      URI::Generic.build({ scheme: client.scheme, host: client.hostname, path: "/#{short_url}" }).to_s
    rescue StandardError => e
      DynamicLinks::Logger.log_error("Error shortening URL: #{e.message}")
      raise e
    end

    # @param client [Client] the client that owns the url
    # @param url [String] the url to be shortened
    def shorten_async(client, url)
      lock_key = locker.generate_lock_key(client, url)

      locker.lock_if_absent(lock_key) do
        short_url = strategy.shorten(url)
        {
          url: url,
          short_url: short_url
        }

        async_worker.perform_later(client, url, short_url, lock_key)
      end
    rescue StandardError => e
      DynamicLinks::Logger.log_error("Error shortening URL asynchronously: #{e.message}")
      raise e
    end
  end
end
