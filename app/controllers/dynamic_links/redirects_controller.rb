module DynamicLinks
  class RedirectsController < ApplicationController
    def show
      short_url = params[:short_url]
      link = ShortenedUrl.find_by(short_url: short_url)

      if link
        redirect_to link.url, status: :found, allow_other_host: true
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end

