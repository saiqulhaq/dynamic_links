module DynamicLinks
  class RedirectsController < ApplicationController

    # Rails will return a 404 if the record is not found
    def show
      short_url = params[:short_url]
      link = ShortenedUrl.find_by!(short_url: short_url)

      raise ActiveRecord::RecordNotFound if link.expired?

      send_event_to_analytics(link)
      redirect_to link.url, status: :found, allow_other_host: true
    end

    private

    def send_event_to_analytics(link)
      return unless defined?(Ahoy::Store)

      # setting up Ahoy Mate gem should be done in the host application
      ahoy.track "Link Clicked", {
        landing_page: link.url,
        shortened_url: link.short_url,
        user_agent: request.user_agent,
        referrer: request.referrer,
        ip: request.ip,
        utm_source: params[:utm_source],
        utm_medium: params[:utm_medium],
        utm_campaign: params[:utm_campaign],
      }
    end
  end
end

