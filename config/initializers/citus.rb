# Ensure proper initialization for Citus when enabled

if ActiveModel::Type::Boolean.new.cast(ENV['CITUS_ENABLED'])
  begin
    # Load the multi-tenant gem
    require 'activerecord-multi-tenant'
    
    # Using after_initialize ensures that all initializers have run before applying Citus-specific configurations.
    Rails.application.config.after_initialize do
      # Set up any Citus-specific configurations
      # For columnar storage issues, you might need specific settings
      CITUS_ENABLE_DDL_PROPAGATION = "SET citus.enable_ddl_propagation TO 'on';"
      ActiveRecord::Base.connection.execute(CITUS_ENABLE_DDL_PROPAGATION)
    end
    
    # Log successful initialization
    Rails.logger.info "Citus multi-tenant support initialized"
  rescue LoadError => e
    Rails.logger.warn "Could not load activerecord-multi-tenant: #{e.message}"
  rescue => e
    Rails.logger.error "Error setting up Citus: #{e.message}"
  end
end
