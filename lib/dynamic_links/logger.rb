module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class Logger    
    def self.instance
      @logger ||= Rails.logger
    end

    def self.log_info(message)
      instance.info(message) if DynamicLinks.configuration.enable_logging
    end

    def self.log_error(message)
      instance.error(message) if DynamicLinks.configuration.enable_logging
    end
  end
end
