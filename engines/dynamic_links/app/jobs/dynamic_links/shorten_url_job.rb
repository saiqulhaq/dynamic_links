# frozen_string_literal: true

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  # This job is used to create a shortened url
  class ShortenUrlJob < ApplicationJob
    queue_as :default

    def perform(client, url, short_url, lock_key)
      locker = DynamicLinks::Async::Locker.new
      strategy = StrategyFactory.get_strategy(DynamicLinks.configuration.shortening_strategy)

      begin
        if strategy.always_growing?
          storage.create!(client: client, url: url, short_url: short_url)
        else
          storage.find_or_create!(client, short_url, url)
        end
        locker.unlock(lock_key)
        DynamicLinks::Logger.log_info("Lock key #{lock_key} deleted after ShortenUrlJob")
      rescue StandardError => e
        DynamicLinks::Logger.log_error("Error in ShortenUrlJob: #{e.message}")
        raise e
      end
    end

    private

    def storage
      @storage ||= ShortenedUrl
    end
  end
end
