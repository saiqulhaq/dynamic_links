module DynamicLinks
  class ShortenUrlJob < ApplicationJob
    queue_as :default

    def perform(client, url, short_url)
      record = ShortenedUrl.find_or_initialize_by(client: client, short_url: short_url)
      record.url = url if record.new_record?
      record.save!
    end
  end
end
