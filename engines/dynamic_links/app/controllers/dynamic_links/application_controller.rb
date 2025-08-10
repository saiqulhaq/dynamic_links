# frozen_string_literal: true

module DynamicLinks
  class ApplicationController < ActionController::API
    before_action :set_security_headers
    before_action :validate_host_header

    # Handle tenant-specific database operations using Rails multi-database features
    # This replaces the previous multi-tenant database strategy approach
    def multi_tenant(client, &)
      # For now, just yield the block since we're using standard single database
      # In the future, this will switch to tenant-specific databases using Rails 8 features
      yield
    end

    # Legacy alias for backward compatibility
    alias with_tenant_database multi_tenant

    private

    def set_security_headers
      response.headers['X-Frame-Options'] = 'SAMEORIGIN'
      response.headers['X-Content-Type-Options'] = 'nosniff'
      response.headers['X-XSS-Protection'] = '1; mode=block'
      response.headers['X-Permitted-Cross-Domain-Policies'] = 'none'
      response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    end

    def validate_host_header
      return unless request.host.present?

      # Check for header injection attempts
      if request.host.include?("\r") || request.host.include?("\n")
        render json: { error: 'Invalid request' }, status: :bad_request
        return
      end

      # For redirects controller, verify the host matches a valid client
      return unless params[:controller] == 'dynamic_links/redirects'

      client = DynamicLinks::Client.find_by(hostname: request.host)
      return if client

      render plain: 'URL not found', status: :not_found
      nil
    end
  end
end
