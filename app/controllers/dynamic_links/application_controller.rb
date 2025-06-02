module DynamicLinks
  class ApplicationController < ActionController::API
    def multi_tenant(client, db_infra_strategy = DynamicLinks.configuration.db_infra_strategy)
      case db_infra_strategy
      when :sharding
        if defined?(::MultiTenant)
          begin
            ::MultiTenant.with(client) { yield }
          rescue => e
            Rails.logger.error "MultiTenant block failed for client=#{client}: #{e.message}"
            raise
          end
        else
          Rails.logger.warn "MultiTenant gem not installed. Skipping tenant context for client=#{client}"
          yield
        end
      else
        yield
      end
    end
  end
end
