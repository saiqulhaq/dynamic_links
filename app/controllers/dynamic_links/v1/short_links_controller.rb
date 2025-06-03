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

      begin
        result = multi_tenant(client) do
          DynamicLinks.generate_short_url(url, client)
        end
        render json: result, status: :created
      rescue DynamicLinks::InvalidURIError
        render json: { error: 'Invalid URL' }, status: :bad_request
      rescue => e
        DynamicLinks::Logger.log_error(e)
        render_error(e, :internal_server_error)
      end
    end

    def expand
      api_key = params.require(:api_key)
      client = DynamicLinks::Client.find_by(api_key: api_key)

      unless client
        render json: { error: 'Invalid API key' }, status: :unauthorized
        return
      end

      begin
        short_link = params[:id]
        full_url = multi_tenant(client) do
          DynamicLinks.resolve_short_url(short_link)
        end

        if full_url
          render json: { full_url: full_url }, status: :ok
        else
          render json: { error: 'Short link not found' }, status: :not_found
        end
      rescue => e
        DynamicLinks::Logger.log_error(e)
        render_error(e, :internal_server_error)
      end
    end

    private

    def check_rest_api_enabled
      unless DynamicLinks.configuration.enable_rest_api
        render json: { error: 'REST API feature is disabled' }, status: :forbidden
      end
    end

    def multi_tenant(client, db_infra_strategy = DynamicLinks.configuration.db_infra_strategy)
      if db_infra_strategy == :sharding
        # Use fully qualified constant name and ensure it's loaded
        if defined?(::MultiTenant) && ::MultiTenant.respond_to?(:with)
          # Use MultiTenant to set the tenant context
          ::MultiTenant.with(client) do
            yield
          end
        else
          Rails.logger.warn 'MultiTenant gem is not properly loaded. Using standard mode.'
          yield
        end
      else
        yield
      end
    rescue => e
      DynamicLinks::Logger.log_error("Error in multi_tenant block: #{e.message}")
      raise e
    end
    
    def render_error(error, status)
      response = { error: 'An error occurred while processing your request' }
      
      # Add detailed error information in test environment or if configured
      if Rails.env.test? || (defined?(DynamicLinks.configuration.show_detailed_errors) && DynamicLinks.configuration.show_detailed_errors)
        response.merge!({
          detailed_error: "#{error.class}: #{error.message}",
          backtrace: error.backtrace&.first(10)
        })
      end
      
      render json: response, status: status
    end
  end
end
