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

    def self.log_error(message_or_exception, context: nil)
      message = format_message(message_or_exception, context)
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

    # Format message from string or exception object so logs include class
    # name and message explicitly (more useful for APM and grep).
    # @param message_or_exception [String, Exception, #to_s]
    # @param context [String, nil] optional prefix
    # @return [String]
    def self.format_message(message_or_exception, context)
      prefix = context.present? ? "#{context}: " : ''
      return "#{prefix}#{message_or_exception}" if message_or_exception.is_a?(String)
      return "#{prefix}#{message_or_exception}" if !message_or_exception.respond_to?(:class)

      klass = message_or_exception.class.name
      msg = message_or_exception.message.to_s
      backtrace = message_or_exception.respond_to?(:backtrace) ? message_or_exception.backtrace&.first&.to_s : nil

      parts = ["#{prefix}#{klass}: #{msg}"]
      parts << "at #{backtrace}" if backtrace.present?
      parts.join(' ')
    end
  end
end
