module DynamicLinks
  class ShortenedUrl < ApplicationRecord
    belongs_to :client, optional: true

    validates :url, presence: true
    validates :short_url, presence: true, uniqueness: true
  end
end
