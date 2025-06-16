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

      multi_tenant(client) do
        render json: DynamicLinks.generate_short_url(url, client), status: :created
      end
    rescue DynamicLinks::InvalidURIError
      render json: { error: 'Invalid URL' }, status: :bad_request
    rescue => e
      DynamicLinks::Logger.log_error(e)
      render json: { error: 'An error occurred while processing your request' }, status: :internal_server_error
    end

    def expand
      api_key = params.require(:api_key)
      client = DynamicLinks::Client.find_by(api_key: api_key)

      unless client
        render json: { error: 'Invalid API key' }, status: :unauthorized
        return
      end

      multi_tenant(client) do
        short_link = params.require(:short_url)
        full_url = DynamicLinks.resolve_short_url(short_link)

        if full_url
          render json: { full_url: full_url }, status: :ok
        else
          render json: { error: 'Short link not found' }, status: :not_found
        end
      end
    rescue => e
      DynamicLinks::Logger.log_error(e)
      render json: { error: 'An error occurred while processing your request' }, status: :internal_server_error
    end

    private

    def check_rest_api_enabled
      unless DynamicLinks.configuration.enable_rest_api
        render json: { error: 'REST API feature is disabled' }, status: :forbidden
      end
    end
  end
end
