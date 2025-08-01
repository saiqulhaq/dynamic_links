# frozen_string_literal: true

module DynamicLinks
  class ApplicationController < ActionController::API
    # Handle tenant-specific database operations using Rails multi-database features
    # This replaces the previous multi-tenant database strategy approach
    def multi_tenant(client, &block)
      # For now, just yield the block since we're using standard single database
      # In the future, this will switch to tenant-specific databases using Rails 8 features
      yield
    end

    # Legacy alias for backward compatibility
    alias_method :with_tenant_database, :multi_tenant
  end
end
