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
    belongs_to :client, optional: true

    validates :url, presence: true
    validates :short_url, presence: true, uniqueness: { scope: :client_id }

    def self.create_or_update(client, short_url, url)
      record = find_or_initialize_by(client: client, short_url: short_url)
      record.url = url if record.new_record?
      record.save!
    end
  end
end
