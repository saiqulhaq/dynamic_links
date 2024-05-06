# == Schema Information
#
# Table name: dynamic_links_shortened_urls
#
#  id         :bigint           not null, primary key
#  client_id  :bigint
#  url        :string(2083)     not null
#  short_url  :string(10)       not null
#  expires_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_dynamic_links_shortened_urls_on_client_id  (client_id)
#  index_dynamic_links_shortened_urls_on_short_url  (short_url) UNIQUE
#
module DynamicLinks
  class ShortenedUrlV2 < ShortenedUrl
    validate :url_is_present?

    def url_is_present?
      url_error unless url.present?
    end

    def url_error
      errors.add(:url, :blank, message: "can't be blank")
    end

    def self.find_or_create!(client, short_url, url)
      return url_error unless url
      transaction do
        record = find_or_create_by!(client: client, short_url: short_url) do |record|
          record.url = url
        end
        record
      end
    rescue ActiveRecord::RecordInvalid => e
      # Log the error and re-raise if needed or return a meaningful error message
      DynamicLinks::Logger.log_error("ShortenedUrl creation failed: #{e.message}")
      raise e
    end
  end
end
