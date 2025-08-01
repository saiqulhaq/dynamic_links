# frozen_string_literal: true

module DynamicLinks
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Rails 8 multi-database support
    # By default, connect to the primary database
    connects_to database: { writing: :primary, reading: :primary }

    # Future tenant database switching can be implemented here
    # Example for future use:
    # def self.with_tenant_database(tenant_name, &block)
    #   tenant_config = {
    #     writing: "tenant_#{tenant_name}".to_sym,
    #     reading: "tenant_#{tenant_name}".to_sym
    #   }
    #
    #   connected_to(database: tenant_config, &block)
    # end
  end
end
