module DynamicLinks
  class RedirectsController < ApplicationController

    # Rails will return a 404 if the record is not found
    def show
      host = request.host
      check_url = DynamicLinks::Client.find_by(hostname: host)
      if check_url.nil?
        render plain: 'URL not found', status: :not_found
        return
      end

      short_url = params[:short_url]
      link = ShortenedUrl.find_by(short_url: short_url)

      if link.nil?
        url = 'https://k4mu4.app.goo.gl'
        redirect_to url + "/#{params[:short_url]}", status: :found, allow_other_host: true
        return
      end
      raise ActiveRecord::RecordNotFound if link.expired?

      redirect_to link.url, status: :found, allow_other_host: true
    end
  end
end
