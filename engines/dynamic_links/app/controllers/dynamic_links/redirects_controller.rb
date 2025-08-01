# frozen_string_literal: true

module DynamicLinks
  class RedirectsController < ApplicationController
    def show
      client = DynamicLinks::Client.find_by({ hostname: request.host })
      unless client
        render plain: 'URL not found', status: :not_found
        return
      end

      with_tenant_database(client) do
        short_url = params[:short_url]
        link = ShortenedUrl.find_by(short_url: short_url)

        if link.nil?
          if DynamicLinks.configuration.enable_fallback_mode && DynamicLinks.configuration.firebase_host.present?
            redirect_to "#{DynamicLinks.configuration.firebase_host}/#{short_url}", status: :found,
                                                                                    allow_other_host: true
          else
            render plain: 'Not found', status: :not_found
          end
          return
        end

        raise ActiveRecord::RecordNotFound if link.expired?

        redirect_to link.url, status: :found, allow_other_host: true
      end
    end
  end
end
