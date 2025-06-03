# Ensure proper initialization for Citus when enabled

if ENV['CITUS_ENABLED'] == 'true'
  begin
    # Load the multi-tenant gem
    require 'activerecord-multi-tenant'
    
    Rails.application.config.after_initialize do
      # Set up any Citus-specific configurations
      # For columnar storage issues, you might need specific settings
      ActiveRecord::Base.connection.execute("SET citus.enable_ddl_propagation TO 'on';")
    end
    
    # Log successful initialization
    Rails.logger.info "Citus multi-tenant support initialized"
  rescue LoadError => e
    Rails.logger.warn "Could not load activerecord-multi-tenant: #{e.message}"
  rescue => e
    Rails.logger.error "Error setting up Citus: #{e.message}"
  end
end
