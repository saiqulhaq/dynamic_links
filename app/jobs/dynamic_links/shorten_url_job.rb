# @author Saiqul Haq <saiqulhaq@gmail.com>

module DynamicLinks
  # This job is used to create a shortened url
  class ShortenUrlJob < ApplicationJob
    queue_as :default

    def perform(client, url, short_url, lock_key)
      ShortenedUrl.find_or_create(client, short_url, url)

      # delete the lock key
      DynamicLinks.configuration.cache_store.delete(lock_key)
    end
  end
end
