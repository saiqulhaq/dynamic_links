module DynamicLinks
  class RedirectsController < ApplicationController
    def show
      short_url = params[:short_url]
      link = ShortenedUrl.find_by(short_url: short_url)

      if link
        ahoy.track "ShortenedUrl Visit", {
          shortened_url: short_url,
          user_agent: request.user_agent,
          referrer: request.referrer
        }

        redirect_to link.url, status: :found, allow_other_host: true
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end

