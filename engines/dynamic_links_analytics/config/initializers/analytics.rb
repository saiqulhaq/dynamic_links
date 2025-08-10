# Configure analytics engine
Rails.application.configure do
  # Ensure analytics jobs are processed
  config.active_job.queue_adapter = :sidekiq if defined?(Sidekiq)

  # Log analytics events (with safety check for logger)
  config.logger.info 'DynamicLinksAnalytics engine loaded and ready to process events' if config.logger
end

# Setup event subscription when the application initializes
Rails.application.config.after_initialize do
  # Verify that the subscription is active (with safety check for logger)
  Rails.logger.info "DynamicLinksAnalytics: Event subscription active for 'link_clicked.dynamic_links'" if Rails.logger

  # Optional: Set up periodic cleanup of old analytics data
  # This could be done via a scheduled job
  if defined?(Sidekiq::Cron)
    # Example: Clean up analytics data older than 2 years
    # Sidekiq::Cron::Job.create(
    #   name: 'Analytics Cleanup',
    #   cron: '0 2 * * 0', # Weekly at 2 AM on Sunday
    #   class: 'DynamicLinksAnalytics::CleanupOldDataJob'
    # )
  end
end
