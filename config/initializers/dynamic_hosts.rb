# frozen_string_literal: true

# Dynamic host authorization for DynamicLinks::Client hostnames
# This allows requests from any hostname that is registered as a DynamicLinks::Client

# Only apply this configuration in production and test environments
# Development environment is handled in config/environments/development.rb
unless Rails.env.development?
  Rails.application.configure do
    # Custom host authorization that allows:
    # 1. Default Rails hosts (localhost, 127.0.0.1, etc.)
    # 2. Any hostname registered in DynamicLinks::Client table
    # 3. The same hostnames with port numbers (for test environment)
    config.host_authorization = {
      exclude: lambda { |request|
        # Always allow health check endpoints
        return true if request.path == '/up'

        host = request.host
        host_with_port = request.host_with_port

        # Allow default hosts
        default_hosts = [
          'localhost',
          '127.0.0.1',
          '0.0.0.0',
          'example.org', # Default Rails test host
          request.local? ? host : nil
        ].compact

        return true if default_hosts.include?(host)

        # Check if this host is registered as a DynamicLinks::Client hostname
        begin
          # Try to find a client with this hostname (with or without port)
          DynamicLinks::Client.exists?(hostname: [host, host_with_port])
        rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
          # If database is not available or table doesn't exist, allow the request
          # This prevents issues during database setup/migrations
          Rails.logger.debug "Dynamic host check failed, allowing request: #{$!.message}"
          true
        end
      }
    }
  end
end
