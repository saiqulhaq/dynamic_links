module DynamicLinks
  class InvalidURIError < ::URI::InvalidURIError; end
  class ConfigurationError < StandardError; end
  class MissingDependency < LoadError; end
  class ShorteningFailed < StandardError; end
end
