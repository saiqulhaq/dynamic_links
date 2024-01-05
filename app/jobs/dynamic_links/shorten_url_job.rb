module DynamicLinks
  class ShortenUrlJob < ApplicationJob
    queue_as :default

    def perform(client, url, short_url)
      # cache_store = ActiveSupport::Cache.lookup_store(DynamicLinks.configuration.cache_store, DynamicLinks.configuration.redis_config)
      # data = cache_store.read(cache_key)
      # return unless data

      # client = DynamicLinks::Client.find(client_id)
      # DynamicLinks.process_url_synchronously(data[:url], data[:short_url], client, StrategyFactory.get_strategy(DynamicLinks.configuration.shortening_strategy))

      # cache_store.delete(cache_key)
    end
  end
end
