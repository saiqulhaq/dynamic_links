module DynamicLinks
  class RedirectsController < ApplicationController
    skip_before_action :validate_host_header

    def show
      # Validate short URL parameter for path traversal
      short_url = params[:short_url]
      unless valid_short_url?(short_url)
        render plain: 'Not found', status: :not_found
        return
      end

      client = DynamicLinks::Client.find_by({ hostname: request.host })
      unless client
        render plain: 'URL not found', status: :not_found
        return
      end

      with_tenant_database(client) do
        link = ShortenedUrl.find_by(short_url: short_url)

        if link.nil?
          if DynamicLinks.configuration.enable_fallback_mode && DynamicLinks.configuration.firebase_host.present?
            # Sanitize the short_url before redirecting
            sanitized_url = sanitize_redirect_url("#{DynamicLinks.configuration.firebase_host}/#{short_url}")
            redirect_to sanitized_url, status: :found, allow_other_host: true
          else
            render plain: 'Not found', status: :not_found
          end
          return
        end

        raise ActiveRecord::RecordNotFound if link.expired?

        # Sanitize the URL before redirecting
        sanitized_url = sanitize_redirect_url(link.url)

        # Verify the URL is still safe after any processing
        unless safe_redirect_url?(sanitized_url)
          render plain: 'Invalid redirect URL', status: :bad_request
          return
        end

        publish_click_event(link)
        redirect_to sanitized_url, status: :found, allow_other_host: true
      end
    rescue ActiveRecord::RecordNotFound
      render plain: 'Not found', status: :not_found
    end

    private

    def valid_short_url?(short_url)
      return false if short_url.blank?
      return false if short_url.include?('..')
      return false if short_url.include?('/')
      return false if short_url.include?("\x00")
      return false if short_url.length > 50

      # Only allow alphanumeric characters and basic URL-safe characters
      short_url.match?(/\A[a-zA-Z0-9_-]+\z/)
    end

    def sanitize_redirect_url(url)
      return url if url.blank?

      # Remove any carriage returns or line feeds to prevent header injection
      sanitized = url.gsub(/[\r\n]/, '')

      # Remove encoded CR/LF characters
      sanitized = sanitized.gsub(/%0[ad]/i, '')

      # Remove any null bytes
      sanitized.gsub("\x00", '')
    end

    def safe_redirect_url?(url)
      return false if url.blank?

      # Basic checks for common attack patterns
      return false if url.include?('<script>')
      return false if url.include?('javascript:')
      return false if url.include?('data:')
      return false if url.include?("\r") || url.include?("\n")

      # Check for encoded attacks
      return false if url.match?(/%0[ad]/i)
      return false if url.include?('%00')

      # Check for header injection keywords
      return false if url.match?(/set-cookie/i)
      return false if url.match?(/location:/i)

      true
    end

    def publish_click_event(link)
      return if link.blank?

      begin
        # Sanitize sensitive data before logging
        user_agent = request.user_agent&.first(500) # Limit length
        referrer = request.referrer&.first(500)

        event_data = {
          shortened_url: link,
          short_url: link.short_url,
          original_url: link.url,
          user_agent: user_agent,
          referrer: referrer,
          ip: request.ip,
          utm_source: params[:utm_source]&.first(100),
          utm_medium: params[:utm_medium]&.first(100),
          utm_campaign: params[:utm_campaign]&.first(100),
          landing_page: request.original_url&.first(500),
          request_method: request.method,
          request_path: request.path,
          request_query_string: request.query_string&.first(1000)
        }

        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)
      rescue StandardError => e
        Rails.logger.error("Failed to publish click event: #{e.message}")
      end
    end
  end
end
