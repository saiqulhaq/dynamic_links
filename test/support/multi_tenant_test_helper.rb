# Helper module to ensure proper MultiTenant testing
module MultiTenantTestHelper
  # Mock MultiTenant for testing if needed
  def self.setup_multi_tenant_mock
    # Stub the MultiTenant module when CITUS is enabled to ensure compatibility
    # with tests that rely on tenant-specific behavior in a non-production environment.
    if ENV['CITUS_ENABLED'] == 'true' && !defined?(::MultiTenant)
      # Create a stub MultiTenant module for testing
      module ::MultiTenant
        def self.with(tenant)
          # Set up thread-local variables to mimic multi_tenant behavior
          Thread.current[:tenant] = tenant
          begin
            yield
          ensure
            Thread.current[:tenant] = nil
          end
        end
      end
      
      # Return true if we created the mock
      true
    else
      # Return false if no mock was needed
      false
    end
  end
  
  # Patch the ActiveRecord models to work with our mock if needed
  def self.patch_models_for_testing
    if ENV['CITUS_ENABLED'] == 'true' && defined?(::MultiTenant)
      # Patch ActiveRecord::Base to include tenant awareness
      unless ActiveRecord::Base.respond_to?(:with_tenant)
        ActiveRecord::Base.class_eval do
          def self.with_tenant(tenant, &block)
            ::MultiTenant.with(tenant, &block)
          end
        end
      end
    end
  end
end

# Auto-setup when loaded
MultiTenantTestHelper.setup_multi_tenant_mock
MultiTenantTestHelper.patch_models_for_testing
