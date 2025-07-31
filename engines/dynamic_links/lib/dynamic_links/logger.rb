# frozen_string_literal: true

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class Logger
    def self.instance
      @instance ||= Rails.logger
    end

    def self.log_info(message)
      instance.info(message)
    end

    def self.log_error(message)
      instance.error(message)
    end

    def self.log_warn(message)
      instance.warn(message)
    end

    def self.log_debug(message)
      instance.debug(message)
    end

    def self.log_fatal(message)
      instance.fatal(message)
    end

    def self.log_unknown(message)
      instance.unknown(message)
    end
  end
end
