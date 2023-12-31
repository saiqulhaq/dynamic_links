module DynamicLinks
  class Configuration
    attr_accessor :shortening_strategy

    def initialize
      @shortening_strategy = :MD5  # Default strategy
    end
  end
end

