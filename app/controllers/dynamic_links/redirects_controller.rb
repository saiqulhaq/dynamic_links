module DynamicLinks
  class RedirectsController < ApplicationController

    # Rails will return a 404 if the record is not found
    def show
      short_url = params[:short_url]
      link = ShortenedUrl.find_by!(short_url: short_url)

      raise ActiveRecord::RecordNotFound if link.expired?

      ahoy.track "ShortenedUrl Visit", {
        shortened_url: short_url,
        user_agent: request.user_agent,
        referrer: request.referrer
      }

      redirect_to link.url, status: :found, allow_other_host: true
    end
  end
end

