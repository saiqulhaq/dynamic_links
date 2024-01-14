module DynamicLinks
  # This job generates short links in the background for KGS strategy
  # It is intended to be run periodically
  # We can find available short links by querying the database with query:
  # ShortenedUrl.where(available: true)
  #
  # To use this strategy, invoke this cli command first:
  # `rails generate dynamic_links:add_kgs_migration`
  class GenerateShortLinksJob < ApplicationJob
    queue_as :default

    # @param num_links [Integer] Number of short links to generate
    def perform(num_links = 100)
      num_links.times do
        # TODO
        # Generate a unique short code
        # Store the short code in the database
      end
    end

    private

    def generate_unique_short_code
      loop do
        # code = # TODO generate a short code using specified strategy
        # break code unless ShortenedUrl.exists?(short_url: code)
      end
    end
  end
end

