module DynamicLinksAnalytics
  class ClickEventProcessor < ApplicationJob
    queue_as :analytics

    # Retry failed jobs with exponential backoff
    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    def perform(event_payload)
      return if event_payload.blank?

      # Extract data from the event payload
      link_click_data = extract_link_click_data(event_payload)

      # Store the click event in the database
      LinkClick.create!(link_click_data)

      Rails.logger.info "Analytics: Processed click event for #{link_click_data[:short_url]}"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Analytics: Failed to save click event - #{e.message}"
      raise e
    rescue StandardError => e
      Rails.logger.error "Analytics: Error processing click event - #{e.message}"
      raise e
    end

    private

    def extract_link_click_data(payload)
      # Build metadata hash with all tracking information
      metadata = build_metadata(payload)

      # Extract client_id from the shortened_url object
      client_id = payload[:shortened_url]&.client_id

      {
        short_url: payload[:short_url],
        original_url: payload[:original_url],
        client_id: client_id,
        ip_address: payload[:ip],
        clicked_at: Time.current,
        metadata: metadata
      }
    end

    def build_metadata(payload)
      {
        user_agent: payload[:user_agent],
        referrer: payload[:referrer],
        utm_source: payload[:utm_source],
        utm_medium: payload[:utm_medium],
        utm_campaign: payload[:utm_campaign],
        landing_page: payload[:landing_page],
        request_method: payload[:request_method],
        request_path: payload[:request_path],
        request_query_string: payload[:request_query_string],
        browser_language: extract_browser_language(payload[:user_agent]),
        is_mobile: is_mobile_device?(payload[:user_agent]),
        country_code: extract_country_code(payload[:ip]),
        processed_at: Time.current.iso8601
      }.compact # Remove nil values
    end

    def extract_browser_language(user_agent)
      return nil if user_agent.blank?

      # Simple language extraction from user agent
      # This could be enhanced with a proper user agent parsing library
      language_match = user_agent.match(/\b([a-z]{2}(-[A-Z]{2})?)\b/)
      language_match&.first
    end

    def is_mobile_device?(user_agent)
      return false if user_agent.blank?

      mobile_keywords = ['Mobile', 'Android', 'iPhone', 'iPad', 'BlackBerry', 'Windows Phone']
      mobile_keywords.any? { |keyword| user_agent.include?(keyword) }
    end

    def extract_country_code(ip_address)
      return nil if ip_address.blank?

      # Placeholder for IP-to-country mapping
      # In a real implementation, you might use a service like MaxMind GeoIP
      # For now, we'll just return nil to avoid external dependencies
      nil
    end
  end
end
