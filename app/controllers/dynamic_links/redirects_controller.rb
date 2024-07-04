module DynamicLinks
  class RedirectsController < ApplicationController
    def show
      short_url = params[:short_url]
      link = ShortenedUrl.find_by!(short_url: short_url)

      raise ActiveRecord::RecordNotFound if link.expires_at.present? && link.expires_at.past?
      
      redirect_to link.url, status: :found, allow_other_host: true
    end
  end
end

