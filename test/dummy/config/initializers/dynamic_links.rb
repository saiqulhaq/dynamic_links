DynamicLinks.configure do |config|
  config.shortening_strategy = if ENV['SHORTENING_STRATEGY'].present?
                                  ENV['SHORTENING_STRATEGY'].to_sym
                                else
                                  # add Logger to warn if the strategy is using the default
                                  DynamicLinks::Logger.log_warn("Using default shortening strategy: #{DynamicLinks::Configuration::DEFAULT_SHORTENING_STRATEGY}")
                                  DynamicLinks::Configuration::DEFAULT_SHORTENING_STRATEGY
                                end
  config.enable_rest_api = true
  config.db_infra_strategy = :standard
  config.async_processing = false
end