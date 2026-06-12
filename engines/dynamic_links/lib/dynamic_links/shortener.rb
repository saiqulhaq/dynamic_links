# frozen_string_literal: true

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class Shortener
    MAX_ATTEMPTS = 3

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
    # @param expires_at [String, Time, nil] optional expiration datetime
    # @return [String] the shortened url
    def shorten(client, url, expires_at: nil)
      parsed_expires_at = parse_expires_at(expires_at)
      attempts = 0
      max_attempts = MAX_ATTEMPTS

      begin
        attempts += 1
        short_url = strategy.shorten(url)

        if strategy.always_growing?
          storage.create!(client: client, url: url, short_url: short_url, expires_at: parsed_expires_at)
        else
          storage.find_or_create!(client, short_url, url, expires_at: parsed_expires_at)
        end
        URI::Generic.build({ scheme: client.scheme, host: client.hostname, path: "/#{short_url}" }).to_s
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
        DynamicLinks::Logger.log_error("Short URL collision on attempt #{attempts}/#{max_attempts} for client #{client&.id}: #{e.message}")
        raise e if attempts >= max_attempts
        retry
      end
    rescue StandardError => e
      DynamicLinks::Logger.log_error("Error shortening URL: #{e.message}")
      raise e
    end

    # @param client [Client] the client that owns the url
    # @param url [String] the url to be shortened
    # @param expires_at [String, Time, nil] optional expiration datetime
    def shorten_async(client, url, expires_at: nil)
      lock_key = locker.generate_lock_key(client, url)
      parsed_expires_at = parse_expires_at(expires_at)

      locker.lock_if_absent(lock_key) do
        short_url = strategy.shorten(url)
        {
          url: url,
          short_url: short_url
        }

        async_worker.perform_later(client, url, short_url, lock_key, parsed_expires_at)
      end
    rescue StandardError => e
      DynamicLinks::Logger.log_error("Error shortening URL asynchronously: #{e.message}")
      raise e
    end

    private

    # Parse expires_at to a Time object
    # @param expires_at [String, Time, nil]
    # @return [Time, nil]
    def parse_expires_at(expires_at)
      return nil if expires_at.nil?
      return expires_at if expires_at.is_a?(Time) || expires_at.is_a?(DateTime)

      Time.zone.parse(expires_at)
    rescue ArgumentError, TypeError => e
      DynamicLinks::Logger.log_error("Error parsing expires_at: #{e.message}")
      nil
    end
  end
end
