require 'rails/engine'

module DynamicLinksAnalytics
  class Engine < ::Rails::Engine
    isolate_namespace DynamicLinksAnalytics

    # Ensure the engine is loaded after the main application
    # so it can subscribe to events from the dynamic_links engine
    config.after_initialize do
      # Subscribe to click events from the dynamic_links engine
      ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |_name, _started, _finished, _unique_id, payload|
        # Extract only serializable data for the job
        shortened_url = payload[:shortened_url]

        serializable_payload = payload.except(:shortened_url)

        # Add serializable data from the shortened_url object
        serializable_payload[:client_id] = shortened_url.client_id if shortened_url.respond_to?(:client_id)

        # Process the event asynchronously to avoid blocking the redirect
        if defined?(DynamicLinksAnalytics::ClickEventProcessor)
          DynamicLinksAnalytics::ClickEventProcessor.perform_later(serializable_payload)
        end
      end
    end

    # Configure ActiveJob for background processing
    initializer 'dynamic_links_analytics.configure_jobs' do |app|
      # Ensure we have a job queue for analytics processing
      app.config.active_job.queue_name_prefix = 'dynamic_links_analytics'
    end

    # Load migrations when the engine is loaded
    initializer 'dynamic_links_analytics.migrations' do |app|
      unless app.root.to_s.match(root.to_s)
        config.paths['db/migrate'].expanded.each do |path|
          app.config.paths['db/migrate'] << path
        end
      end
    end
  end
end
