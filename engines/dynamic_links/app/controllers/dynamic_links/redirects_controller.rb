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

        publish_click_event(link)
        redirect_to link.url, status: :found, allow_other_host: true
      end
    end

    private

    def publish_click_event(link)
      return if link.blank?

      event_data = {
        shortened_url: link,
        short_url: link.short_url,
        original_url: link.url,
        user_agent: request.user_agent,
        referrer: request.referrer,
        ip: request.ip,
        utm_source: params[:utm_source],
        utm_medium: params[:utm_medium],
        utm_campaign: params[:utm_campaign],
        landing_page: request.original_url,
        request: request
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)
    end
  end
end
