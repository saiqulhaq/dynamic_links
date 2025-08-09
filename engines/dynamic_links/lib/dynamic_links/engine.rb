# frozen_string_literal: true

require 'dynamic_links/host_authorization'

module DynamicLinks
  class Engine < ::Rails::Engine
    isolate_namespace DynamicLinks

    # Configure host authorization when the engine initializes
    initializer 'dynamic_links.configure_host_authorization', after: :load_config_initializers do |app|
      DynamicLinks::HostAuthorization.configure!(app.config)
    end
  end
end
