# frozen_string_literal: true

module DynamicLinks
  # Host authorization module that allows requests to registered client hostnames
  # This ensures that Rails' host authorization allows any hostname that is
  # registered as a DynamicLinks::Client hostname.
  class HostAuthorization
    # Default hosts that should always be allowed
    DEFAULT_ALLOWED_HOSTS = [
      'localhost',
      '127.0.0.1',
      '0.0.0.0',
      'example.org' # Default Rails test host
    ].freeze

    class << self
      # Configure Rails host authorization to allow dynamic client hostnames
      # @param config [Rails::Application::Configuration] Rails application configuration
      def configure!(config)
        if Rails.env.development?
          # In development, allow all hosts for convenience
          config.hosts.clear if config.hosts
          config.host_authorization = { exclude: ->(_request) { true } }
        else
          # In production/test, use dynamic host authorization
          config.host_authorization = {
            exclude: lambda { |request|
              allowed?(request)
            }
          }
        end
      end

      # Check if a request should be allowed based on host authorization rules
      # @param request [ActionDispatch::Request] The incoming request
      # @return [Boolean] true if the request should be allowed
      def allowed?(request)
        # Always allow health check endpoints
        return true if health_check_path?(request.path)

        host = request.host
        host_with_port = request.host_with_port

        # Allow default hosts
        return true if default_host_allowed?(host, request)

        # Check if this host is registered as a DynamicLinks::Client hostname
        client_hostname_allowed?(host, host_with_port)
      end

      private

      # Check if the path is a health check endpoint
      # @param path [String] Request path
      # @return [Boolean]
      def health_check_path?(path)
        path == '/up'
      end

      # Check if the host is in the default allowed hosts list
      # @param host [String] The request host
      # @param request [ActionDispatch::Request] The request object
      # @return [Boolean]
      def default_host_allowed?(host, request)
        allowed_hosts = DEFAULT_ALLOWED_HOSTS.dup
        allowed_hosts << host if request.local?
        allowed_hosts.include?(host)
      end

      # Check if the hostname is registered as a DynamicLinks::Client hostname
      # @param host [String] The request host without port
      # @param host_with_port [String] The request host with port
      # @return [Boolean]
      def client_hostname_allowed?(host, host_with_port)
        # Try to find a client with this hostname (with or without port)
        DynamicLinks::Client.exists?(hostname: [host, host_with_port])
      rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished => e
        # If database is not available or table doesn't exist, allow the request
        # This prevents issues during database setup/migrations
        Rails.logger&.debug("DynamicLinks host authorization check failed, allowing request: #{e.message}")
        true
      end
    end
  end
end
