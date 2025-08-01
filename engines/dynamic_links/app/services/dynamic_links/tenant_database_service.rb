# frozen_string_literal: true

module DynamicLinks
  # Service to handle tenant-specific database connections using Rails 8 multi-database features
  # This replaces the previous Citus-based multi-tenancy approach
  class TenantDatabaseService
    class << self
      # Execute a block with a specific tenant's database connection
      # For now, this just executes the block as-is since we're using a single database
      # In the future, this can be enhanced to switch to tenant-specific databases
      #
      # @param client [DynamicLinks::Client] The client/tenant
      # @param block [Proc] The block to execute with the tenant's database
      def with_tenant_database(client, &block)
        # For single database approach, just execute the block
        # Future enhancement: Switch to tenant-specific database based on client configuration
        #
        # Example future implementation:
        # if client.has_dedicated_database?
        #   tenant_name = client.database_identifier
        #   ApplicationRecord.connected_to(
        #     database: { writing: "tenant_#{tenant_name}".to_sym, reading: "tenant_#{tenant_name}".to_sym },
        #     &block
        #   )
        # else
        #   yield
        # end

        yield
      end

      # Check if a client has a dedicated database
      # This is a placeholder for future implementation
      def tenant_has_dedicated_database?(client)
        # Future implementation: Check client configuration for dedicated database
        # client.dedicated_database? || client.database_config.present?
        false
      end

      # Get the database identifier for a tenant
      # This is a placeholder for future implementation
      def tenant_database_identifier(client)
        # Future implementation: Return tenant-specific database identifier
        # client.database_identifier || "tenant_#{client.id}"
        "primary"
      end
    end
  end
end
