module DynamicLinks
  class V1::ShortLinksController < ApplicationController
    before_action :check_rest_api_enabled

    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from DynamicLinks::InvalidURIError, with: :handle_invalid_uri
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

    def create
      url = params.require(:url)
      api_key = params.require(:api_key)
      client = DynamicLinks::Client.find_by(api_key: api_key)

      unless client
        render json: { error: 'Invalid API key' }, status: :unauthorized
        return
      end

      multi_tenant(client) do
        result = DynamicLinks.generate_short_url(url, client)
        render json: result, status: :created
      end
    rescue ActiveRecord::ConnectionNotEstablished => e
      logger.error("Database connection error: #{e.message}")
      render json: { error: 'Database connection error' }, status: :internal_server_error
    rescue DynamicLinks::InvalidURIError => e
      logger.error("Invalid URI: #{e.message}")
      render json: { error: 'Invalid URL' }, status: :bad_request
    rescue => e
      logger.error("Unexpected error in create: #{e.class} - #{e.message}")
      DynamicLinks::Logger.log_error(e)
      render json: { error: 'An error occurred while processing your request' }, status: :internal_server_error
    end


    def expand
      short_link = params.require(:short_url)
      client = find_client_from_api_key

      return unless client

      multi_tenant(client) do
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

    def find_client_from_api_key
      api_key = params.require(:api_key)
      client = DynamicLinks::Client.find_by(api_key: api_key)

      unless client
        render json: { error: 'Invalid API key' }, status: :unauthorized
      end

      client
    end

    def handle_parameter_missing(exception)
      render json: { error: "Missing parameter: #{exception.param}" }, status: :bad_request
    end

    def handle_invalid_uri
      render json: { error: 'Invalid URL' }, status: :bad_request
    end

    def handle_not_found
      render json: { error: 'Short link not found' }, status: :not_found
    end
  end
end
