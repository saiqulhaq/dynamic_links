# @author Saiqul Haq <saiqulhaq@gmail.com>

module DynamicLinks
  class ShortenUrlJob < ApplicationJob
    queue_as :default

    def perform(client, url, short_url, lock_key)
      ShortenedUrl.create_or_update(client, short_url, url)

      # delete the lock key
      DynamicLinks.configuration.cache_store.delete(lock_key)
    end
  end
end
