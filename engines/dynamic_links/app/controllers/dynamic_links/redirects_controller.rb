require 'ahoy_matey'

module DynamicLinks
  class RedirectsController < ApplicationController
    def show
      client = DynamicLinks::Client.find_by({ hostname: request.host })
      unless client
        render plain: 'URL not found', status: :not_found
        return
      end

      with_tenant_database(client) do
        short_url = params[:short_url]
        link = ShortenedUrl.find_by(short_url: short_url)

        if link.nil?
          if DynamicLinks.configuration.enable_fallback_mode && DynamicLinks.configuration.firebase_host.present?
            redirect_to "#{DynamicLinks.configuration.firebase_host}/#{short_url}", status: :found,
                                                                                    allow_other_host: true
          else
            render plain: 'Not found', status: :not_found
          end
          return
        end

        raise ActiveRecord::RecordNotFound if link.expired?

        send_event_to_analytics(link)
        redirect_to link.url, status: :found, allow_other_host: true
      end
    end

    private

    def send_event_to_analytics(link)
      return unless defined?(Ahoy::Store) || link.blank?

      ahoy.track 'Link Clicked', {
        shortened_url: link.short_url,
        original_url: link.url,
        user_agent: request.user_agent,
        referrer: request.referrer,
        ip: request.ip,
        device_type: ahoy.visit_properties['device_type'],
        os: ahoy.visit_properties['os'],
        browser: ahoy.visit_properties['browser'],
        utm_source: params[:utm_source],
        utm_medium: params[:utm_medium],
        utm_campaign: params[:utm_campaign],
        landing_page: request.original_url
      }
    end
  end
end
