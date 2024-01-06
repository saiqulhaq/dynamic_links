module DynamicLinks
  class InvalidURIError < ::URI::InvalidURIError; end
  class ConfigurationError < StandardError; end
  class UnknownCacheStoreType < StandardError; end
  class MissingDependency < LoadError; end
end
