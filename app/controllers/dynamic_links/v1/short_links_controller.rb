module DynamicLinks
  class V1::ShortLinksController < ApplicationController
    before_action :check_rest_api_enabled

    def create
      url = params.require(:url)
      client = DynamicLinks::Client.find_by(api_key: params.require(:api_key))

      unless client
        render json: { error: 'Invalid API key' }, status: :unauthorized
        return
      end

      render json: DynamicLinks.generate_short_url(url, client), status: :created
    rescue DynamicLinks::InvalidURIError
      render json: { error: 'Invalid URL' }, status: :bad_request
    end

    private

    def check_rest_api_enabled
      unless DynamicLinks.configuration.enable_rest_api
        render json: { error: 'REST API feature is disabled' }, status: :forbidden
      end
    end
  end
end
