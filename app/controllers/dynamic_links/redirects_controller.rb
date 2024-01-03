module DynamicLinks
  class RedirectsController < ApplicationController
    def show
      short_url = params[:short_url]
      link = ShortenedUrl.find_by(short_url: short_url)

      if link
        redirect_to link.url, status: :found
      else
        render_not_found
      end
    end

    private

    def render_not_found
      # Render a 404 page or similar
      render file: 'public/404.html', status: :not_found, layout: false
    end
  end
end

