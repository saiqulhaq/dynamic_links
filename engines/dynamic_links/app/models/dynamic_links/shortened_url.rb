# frozen_string_literal: true

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
  class ShortenedUrl < ApplicationRecord
    include DynamicLinksAnalytics::AnalyticsAssociation if defined?(DynamicLinksAnalytics::AnalyticsAssociation)

    belongs_to :client

    validates :url, presence: true
    validates :short_url, presence: true, uniqueness: { scope: :client_id }
    validate :short_url_length_within_limit

    def self.find_or_create!(client, short_url, url)
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

    def expired?
      expires_at&.past?
    end

    private

    def short_url_length_within_limit
      max_length = DynamicLinks.configuration.max_shortened_url_length
      return unless max_length.is_a?(Integer) && max_length.positive?
      return unless short_url.present? && short_url.length > max_length

      errors.add(:short_url, "is too long (maximum is #{max_length} characters)")
    end
  end
end
