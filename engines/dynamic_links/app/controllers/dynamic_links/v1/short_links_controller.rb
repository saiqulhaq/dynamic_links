# frozen_string_literal: true

module DynamicLinks
  module V1
    class ShortLinksController < ApplicationController
      before_action :check_rest_api_enabled
      before_action :validate_request_size
      before_action :validate_content_type
      before_action :validate_http_method

      def create
        url = params.require(:url)
        api_key = params.require(:api_key)

        # Validate API key format
        unless valid_api_key?(api_key)
          render json: { error: 'Invalid API key' }, status: :unauthorized
          return
        end

        client = DynamicLinks::Client.find_by(api_key: api_key)

        unless client
          render json: { error: 'Invalid API key' }, status: :unauthorized
          return
        end

        # Additional URL validation beyond what's in DynamicLinks.generate_short_url
        unless safe_url?(url)
          render json: { error: 'Invalid URL' }, status: :bad_request
          return
        end

        with_tenant_database(client) do
          render json: DynamicLinks.generate_short_url(url, client), status: :created
        end
      rescue DynamicLinks::InvalidURIError
        render json: { error: 'Invalid URL' }, status: :bad_request
      rescue ActionController::ParameterMissing
        render json: { error: 'Missing required parameters' }, status: :bad_request
      rescue StandardError => e
        DynamicLinks::Logger.log_error(e)
        render json: { error: 'An error occurred while processing your request' }, status: :internal_server_error
      end

      def expand
        api_key = params.require(:api_key)

        unless valid_api_key?(api_key)
          render json: { error: 'Invalid API key' }, status: :unauthorized
          return
        end

        client = DynamicLinks::Client.find_by(api_key: api_key)

        unless client
          render json: { error: 'Invalid API key' }, status: :unauthorized
          return
        end

        with_tenant_database(client) do
          short_link = params.require(:short_url)
          full_url = DynamicLinks.resolve_short_url(short_link)

          if full_url
            render json: { full_url: full_url }, status: :ok
          else
            render json: { error: 'Short link not found' }, status: :not_found
          end
        end
      rescue ActionController::ParameterMissing
        render json: { error: 'Missing required parameters' }, status: :bad_request
      rescue StandardError => e
        DynamicLinks::Logger.log_error(e)
        render json: { error: 'An error occurred while processing your request' }, status: :internal_server_error
      end

      def find_or_create
        url = params.require(:url)
        api_key = params.require(:api_key)

        unless valid_api_key?(api_key)
          render json: { error: 'Invalid API key' }, status: :unauthorized
          return
        end

        client = DynamicLinks::Client.find_by(api_key: api_key)

        unless client
          render json: { error: 'Invalid API key' }, status: :unauthorized
          return
        end

        unless safe_url?(url)
          render json: { error: 'Invalid URL' }, status: :bad_request
          return
        end

        with_tenant_database(client) do
          short_link = DynamicLinks.find_short_link(url, client)

          if short_link
            render json: {
              shortLink: short_link[:short_url],
              previewLink: "#{short_link[:short_url]}?preview=true",
              warning: []
            }, status: :ok
          else
            render json: DynamicLinks.generate_short_url(url, client), status: :created
          end
        end
      rescue ActionController::ParameterMissing
        render json: { error: 'Missing required parameters' }, status: :bad_request
      rescue StandardError => e
        DynamicLinks::Logger.log_error(e)
        render json: { error: 'An error occurred while processing your request' }, status: :internal_server_error
      end

      private

      def check_rest_api_enabled
        return if DynamicLinks.configuration.enable_rest_api

        render json: { error: 'REST API feature is disabled' }, status: :forbidden
      end

      def validate_request_size
        # Limit request size to prevent DoS
        max_size = 50.kilobytes
        if request.content_length && request.content_length > max_size
          render json: { error: 'Request too large' }, status: :content_too_large
          return
        end

        # Also check parameter sizes
        return unless params[:url] && params[:url].length > 2083

        render json: { error: 'URL too long' }, status: :content_too_large
        nil
      end

      def validate_content_type
        return unless request.post? || request.put? || request.patch?

        # Get the raw content type header to check for injection attempts
        raw_content_type = request.get_header('CONTENT_TYPE')
        # Block malicious content types with header injection
        if raw_content_type.present? && (raw_content_type.include?("\r") || raw_content_type.include?("\n"))
          render json: { error: 'Invalid content type' }, status: :bad_request
          return
        end

        begin
          content_type = request.content_type
        rescue StandardError => e
          # If content type parsing fails, it's likely malicious
          render json: { error: 'Invalid content type' }, status: :bad_request
          return
        end

        return unless content_type

        # Only allow safe content types
        safe_types = [
          'application/json',
          'application/x-www-form-urlencoded',
          'multipart/form-data'
        ]

        return if safe_types.any? { |type| content_type.start_with?(type) }

        render json: { error: 'Unsupported content type' }, status: :unsupported_media_type
        nil
      end

      def validate_http_method
        allowed_methods = %w[GET POST]

        return if allowed_methods.include?(request.method)

        render json: { error: 'Method not allowed' }, status: :method_not_allowed
        nil
      end

      def valid_api_key?(api_key)
        return false if api_key.blank?
        return false if api_key.include?("\x00") || api_key.include?("\r") || api_key.include?("\n")
        return false if api_key.length > 255 || api_key.length < 3

        true
      end

      def safe_url?(url)
        return false if url.blank?
        return false if url.length > 2083

        # Check for XSS attempts
        return false if url.match?(/<script|javascript:|onerror=|onload=|onclick=/i)

        # Use the enhanced validator
        DynamicLinks::Validator.valid_url?(url)
      end
    end
  end
end
