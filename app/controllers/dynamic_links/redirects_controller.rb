module DynamicLinks
  class RedirectsController < ApplicationController

    # Rails will return a 404 if the record is not found
    def show
      short_url = params[:short_url]
      link = ShortenedUrl.find_by!(short_url: short_url)

      raise ActiveRecord::RecordNotFound if link.expired?

      redirect_to link.url, status: :found, allow_other_host: true
    end
  end
end

