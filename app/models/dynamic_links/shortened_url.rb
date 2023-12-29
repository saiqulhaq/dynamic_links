module DynamicLinks
  class ShortenedUrl < ApplicationRecord
    belongs_to :client

    validates :url, presence: true
    validates :short_url, presence: true, uniqueness: true
  end
end
