module DynamicLinks
  class RedirectsController < ApplicationController
    def show
      short_url = params[:short_url]
      link = ShortenedUrl.find_by(short_url: short_url)

      if link
        ahoy.track "ShortenedUrl Visit", {
          shortened_url: short_url,
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

        redirect_to link.url, status: :found, allow_other_host: true
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end

