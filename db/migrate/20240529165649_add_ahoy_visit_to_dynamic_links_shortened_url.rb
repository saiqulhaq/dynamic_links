class AddAhoyVisitToDynamicLinksShortenedUrl < ActiveRecord::Migration[7.1]
  def change
    add_reference :dynamic_links_shortened_urls, :ahoy_visit
  end
end
