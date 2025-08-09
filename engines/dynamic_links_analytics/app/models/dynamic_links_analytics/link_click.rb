module DynamicLinksAnalytics
  class LinkClick < ApplicationRecord
    # This model stores analytics data for link clicks
    # Uses JSONB for flexible metadata storage with proper indexing

    # Validations
    validates :short_url, presence: true
    validates :original_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
    validates :clicked_at, presence: true
    validates :ip_address, presence: true

    # Scopes for common queries
    scope :recent, -> { order(clicked_at: :desc) }
    scope :for_short_url, ->(short_url) { where(short_url: short_url) }
    scope :for_client, ->(client_id) { where(client_id: client_id) }
    scope :with_utm_source, ->(source) { where("metadata ->> 'utm_source' = ?", source) }
    scope :with_utm_campaign, ->(campaign) { where("metadata ->> 'utm_campaign' = ?", campaign) }
    scope :from_referrer, ->(referrer) { where("metadata ->> 'referrer' ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(referrer)}%") }
    scope :by_user_agent, ->(user_agent) { where("metadata ->> 'user_agent' ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(user_agent)}%") }
    scope :in_date_range, ->(start_date, end_date) { where(clicked_at: start_date..end_date) }

    # Analytics methods
    def self.clicks_count_for(short_url)
      for_short_url(short_url).count
    end

    def self.unique_visitors_for(short_url)
      for_short_url(short_url).distinct.count(:ip_address)
    end

    def self.top_referrers(limit = 10)
      where.not("metadata ->> 'referrer'" => [nil, ''])
           .group("metadata ->> 'referrer'")
           .order('count_all DESC')
           .limit(limit)
           .count
    end

    def self.top_user_agents(limit = 10)
      where.not("metadata ->> 'user_agent'" => [nil, ''])
           .group("metadata ->> 'user_agent'")
           .order('count_all DESC')
           .limit(limit)
           .count
    end

    def self.utm_source_breakdown
      where("metadata ? 'utm_source'")
        .where.not("metadata ->> 'utm_source' = ''")
        .group("metadata ->> 'utm_source'")
        .order('count_all DESC')
        .count
    end

    def self.utm_campaign_breakdown
      where.not("metadata ->> 'utm_campaign'" => [nil, ''])
           .group("metadata ->> 'utm_campaign'")
           .order('count_all DESC')
           .count
    end

    def self.daily_clicks(days = 30)
      where(clicked_at: days.days.ago..Time.current)
        .group('DATE(clicked_at)')
        .order('date_clicked_at')
        .count
    end

    def self.hourly_clicks(hours = 24)
      where(clicked_at: hours.hours.ago..Time.current)
        .group("DATE_TRUNC('hour', clicked_at)")
        .order('date_trunc_hour_clicked_at')
        .count
    end

    # Instance methods
    def utm_params
      {
        source: metadata&.dig('utm_source'),
        medium: metadata&.dig('utm_medium'),
        campaign: metadata&.dig('utm_campaign')
      }.compact
    end

    def browser_info
      metadata&.dig('user_agent') || 'Unknown'
    end

    def referrer_domain
      return nil if metadata&.dig('referrer').blank?

      begin
        URI.parse(metadata['referrer']).host
      rescue URI::Error
        nil
      end
    end
  end
end
