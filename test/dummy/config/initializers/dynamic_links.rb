DynamicLinks.configure do |config|
  config.shortening_strategy = :nano_id
  config.enable_rest_api = true
  config.db_infra_strategy = :standard
  config.async_processing = false
end