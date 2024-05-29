module DynamicLinks
  class RedirectsController < ApplicationController
    def show
      client = DynamicLinks::Client.find_by({ hostname: request.host })
      unless client
        render plain: 'URL not found', status: :not_found
        return
      end

      multi_tenant(client) do
        short_url = params[:short_url]
        link = ShortenedUrl.find_by(short_url: short_url)

        if link.nil?
          if DynamicLinks.configuration.enable_fallback_mode && DynamicLinks.configuration.firebase_host.present?
            redirect_to "#{DynamicLinks.configuration.firebase_host}/#{short_url}", status: :found, allow_other_host: true
          else
            render plain: 'Not found', status: :not_found
          end
          return
        end

        raise ActiveRecord::RecordNotFound if link.expired?

        if link
          ahoy.track "ShortenedUrl Visit", {
            shortened_url: short_url,
            user_agent: request.user_agent,
            referrer: request.referrer
          }
        end

        redirect_to link.url, status: :found, allow_other_host: true
      end
    end
  end
end
