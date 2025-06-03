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
    belongs_to :client
    multi_tenant :client if respond_to?(:multi_tenant)

    validates :url, presence: true
    validates :short_url, presence: true, uniqueness: { scope: :client_id }

    def self.find_or_create!(client, short_url, url)
      if respond_to?(:multi_tenant) && defined?(::MultiTenant)
        # When Citus is enabled, use MultiTenant.with
        ::MultiTenant.with(client) do
          transaction do
            # When in a multi-tenant context, client is automatically set by the tenant
            # We need to handle creation differently to ensure validation errors are raised
            begin
              record = where(short_url: short_url).first_or_initialize
              if record.new_record?
                record.url = url
                record.save!
              end
              record
            rescue ActiveRecord::RecordInvalid => e
              DynamicLinks::Logger.log_error("ShortenedUrl creation failed: #{e.message}")
              raise e
            end
          end
        end
      else
        # Original implementation for standard PostgreSQL
        transaction do
          record = find_or_create_by!(client: client, short_url: short_url) do |record|
            record.url = url
          end
          record
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      # Log the error and re-raise if needed or return a meaningful error message
      DynamicLinks::Logger.log_error("ShortenedUrl creation failed: #{e.message}")
      raise e
    end

    def expired?
      expires_at&.past?
    end
  end
end
