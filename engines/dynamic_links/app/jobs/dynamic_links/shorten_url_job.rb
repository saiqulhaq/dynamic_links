# frozen_string_literal: true

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  # This job is used to create a shortened url
  class ShortenUrlJob < ApplicationJob
    queue_as :default
    MAX_ATTEMPTS = 3

    def perform(client, url, short_url, lock_key, expires_at = nil)
      locker = DynamicLinks::Async::Locker.new
      strategy = StrategyFactory.get_strategy(DynamicLinks.configuration.shortening_strategy)

      attempts = 0
      short_url_to_save = short_url

      begin
        attempts += 1

        if strategy.always_growing?
          storage.create!(client: client, url: url, short_url: short_url_to_save, expires_at: expires_at)
        else
          storage.find_or_create!(client, short_url_to_save, url, expires_at: expires_at)
        end

        locker.unlock(lock_key)
        DynamicLinks::Logger.log_info("Lock key #{lock_key} deleted after ShortenUrlJob")
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
        # Only retry when the failure is a short-code uniqueness
        # collision. Other validation errors propagate immediately so
        # we don't mask them as collisions.
        raise e unless short_code_collision?(e)

        if attempts >= MAX_ATTEMPTS
          DynamicLinks::Logger.log_error("Short URL collision after #{attempts} attempts for client #{client&.id}: #{e.message}")
          raise e
        end

        # Mint a fresh short code and try again. The strategy (e.g.
        # NanoID) is expected to produce a different candidate on
        # each call.
        short_url_to_save = strategy.shorten(url)
        DynamicLinks::Logger.log_error("Short URL collision on attempt #{attempts}/#{MAX_ATTEMPTS} for client #{client&.id}: #{e.message}")
        retry
      rescue StandardError => e
        DynamicLinks::Logger.log_error("Error in ShortenUrlJob: #{e.message}")
        raise e
      end
    end

    private

    def storage
      @storage ||= ShortenedUrl
    end

    def short_code_collision?(error)
      return true if error.is_a?(ActiveRecord::RecordNotUnique)

      return false unless error.is_a?(ActiveRecord::RecordInvalid)

      Array(error.record&.errors&.[](:short_url)).any? do |msg|
        msg.to_s.include?('taken') || msg.to_s.include?('uniqueness')
      end
    end
  end
end
