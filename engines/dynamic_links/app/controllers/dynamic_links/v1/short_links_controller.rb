# frozen_string_literal: true

module DynamicLinks
  module V1
    class ShortLinksController < ApplicationController
      before_action :check_rest_api_enabled
      before_action :validate_request_size
      before_action :validate_content_type
      before_action :validate_http_method

      def create
        params_tuple = extract_short_link_params
        return if params_tuple.nil?

        url, api_key, expires_at = params_tuple

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

        # Validate expires_at if provided
        if expires_at.present? && !valid_expires_at?(expires_at)
          render json: { error: 'Invalid expires_at format. Use ISO 8601 format (e.g., 2025-12-31T23:59:59Z)' }, status: :bad_request
          return
        end

        with_tenant_database(client) do
          render json: DynamicLinks.generate_short_url(url, client, expires_at: expires_at), status: :created
        end
      rescue DynamicLinks::InvalidURIError
        render json: { error: 'Invalid URL' }, status: :bad_request
      rescue ActionController::ParameterMissing
        render json: { error: 'Missing required parameters' }, status: :bad_request
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
        DynamicLinks::Logger.log_error(e, context: 'Short URL collision')
        render json: { error: 'Short URL generation conflict, please retry' }, status: :conflict
      rescue ActiveRecord::ConnectionTimeoutError, ActiveRecord::ConnectionNotEstablished, ActiveRecord::AdapterTimeout => e
        DynamicLinks::Logger.log_error(e, context: 'Database connection error')
        render json: { error: 'Service temporarily unavailable' }, status: :service_unavailable
      rescue StandardError => e
        DynamicLinks::Logger.log_error(e, context: 'create short link')
        render json: {
          error: 'An error occurred while processing your request',
          error_class: e.class.name
        }, status: :internal_server_error
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
          unless short_link.is_a?(String)
            render json: { error: 'Invalid short_url' }, status: :bad_request
            return
          end

          full_url = DynamicLinks.resolve_short_url(short_link)

          if full_url
            render json: { full_url: full_url }, status: :ok
          else
            render json: { error: 'Short link not found' }, status: :not_found
          end
        end
      rescue ActionController::ParameterMissing
        render json: { error: 'Missing required parameters' }, status: :bad_request
      rescue ActiveRecord::ConnectionTimeoutError, ActiveRecord::ConnectionNotEstablished, ActiveRecord::AdapterTimeout => e
        DynamicLinks::Logger.log_error(e, context: 'Database connection error')
        render json: { error: 'Service temporarily unavailable' }, status: :service_unavailable
      rescue StandardError => e
        DynamicLinks::Logger.log_error(e, context: 'expand short link')
        render json: {
          error: 'An error occurred while processing your request',
          error_class: e.class.name
        }, status: :internal_server_error
      end

      def find_or_create
        params_tuple = extract_short_link_params
        return if params_tuple.nil?

        url, api_key, expires_at = params_tuple

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

        # Validate expires_at if provided
        if expires_at.present? && !valid_expires_at?(expires_at)
          render json: { error: 'Invalid expires_at format. Use ISO 8601 format (e.g., 2025-12-31T23:59:59Z)' }, status: :bad_request
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
            render json: DynamicLinks.generate_short_url(url, client, expires_at: expires_at), status: :created
          end
        end
      rescue ActionController::ParameterMissing
        render json: { error: 'Missing required parameters' }, status: :bad_request
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
        DynamicLinks::Logger.log_error(e, context: 'Short URL collision')
        render json: { error: 'Short URL generation conflict, please retry' }, status: :conflict
      rescue ActiveRecord::ConnectionTimeoutError, ActiveRecord::ConnectionNotEstablished, ActiveRecord::AdapterTimeout => e
        DynamicLinks::Logger.log_error(e, context: 'Database connection error')
        render json: { error: 'Service temporarily unavailable' }, status: :service_unavailable
      rescue StandardError => e
        DynamicLinks::Logger.log_error(e, context: 'find_or_create short link')
        render json: {
          error: 'An error occurred while processing your request',
          error_class: e.class.name
        }, status: :internal_server_error
      end

      private

      # Pull and type-check the standard short-link params.
      # Returns [url, api_key, expires_at] when valid, or nil when the
      # request should be short-circuited with a 400 response (already
      # rendered). Callers MUST `return` immediately if this returns nil.
      def extract_short_link_params
        url = params[:url]
        api_key = params[:api_key]
        expires_at = params[:expires_at]

        if params[:api_key].nil? && params[:url].nil?
          render json: { error: 'Missing required parameters' }, status: :bad_request
          return nil
        end

        unless url.is_a?(String) && url.present?
          render json: { error: 'Invalid url' }, status: :bad_request
          return nil
        end

        unless api_key.is_a?(String) && api_key.present?
          render json: { error: 'Invalid api_key' }, status: :bad_request
          return nil
        end

        if expires_at.present? && !expires_at.is_a?(String)
          render json: { error: 'Invalid expires_at' }, status: :bad_request
          return nil
        end

        [url, api_key, expires_at]
      end

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
        url_param = params[:url]
        return unless url_param.is_a?(String) && url_param.length > 2083

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

      def valid_expires_at?(expires_at)
        return false if expires_at.blank?

        # Try to parse as datetime
        Time.zone.parse(expires_at)
        true
      rescue ArgumentError, TypeError
        false
      end
    end
  end
end
