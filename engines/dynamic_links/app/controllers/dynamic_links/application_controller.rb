module DynamicLinks
  class ApplicationController < ActionController::API
    def multi_tenant(client, db_infra_strategy = DynamicLinks.configuration.db_infra_strategy)
      if db_infra_strategy == :sharding
        if defined?(::MultiTenant)
          ::MultiTenant.with(client) do
            yield
          end
        else
          # Rails.logger.warn 'MultiTenant gem is not installed. Please install it to use sharding strategy'
          DynamicLinks::Logger.log_warn('MultiTenant gem is not installed. Please install it to use sharding strategy')
          
          yield
        end
      else
        yield
      end
    end
  end
end
