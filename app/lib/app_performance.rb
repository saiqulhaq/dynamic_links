# frozen_string_literal: true

# This module provides a consistent way to interact with ElasticAPM throughout the application,
# while respecting the toggle configuration. If ElasticAPM is disabled, all methods become no-ops.
# ElasticAPM gem already wraps each process in a transaction, so we don't need to wrap it again.
module AppPerformance
  class << self
    # Wrap a block in a span with the given name and type
    # @param name [String] Name of the span
    # @param type [String, nil] Type of the span (e.g., 'db', 'app')
    # @param context [Hash, nil] Optional context data for the span
    # @yield [span] If a block is given, the span will be ended when the block exits
    # @return [Object, nil] The return value of the block or nil if APM is disabled
    def with_span(name, type = nil, context: nil)
      return yield(nil) if block_given? && !apm_available?
      return unless apm_available?

      ElasticAPM.with_span(name, type, context: context) do |spn|
        yield(spn)
      end
    end


    # Add a label to the current transaction.
    # Labels are basic key-value pairs that are indexed in your Elasticsearch database and therefore searchable.
    # The value can be a string, nil, numeric or boolean.
    # Be aware that labels are indexed in Elasticsearch. Using too many unique keys will result in Mapping explosion
    # @!attribute [String, Symbol] key Label key
    # @!attribute [String, Numeric, Boolean] value Label value
    # @return [void]
    def set_label(key, value)
      return unless apm_available?

      ElasticAPM.set_label(key, value)
    end

    # Add the current user to the current transaction’s context.
    # Arguments:
    # user: An object representing the user
    # Returns the given user
    # @param user [Hash, Object] User information
    def set_user(user)
      return unless apm_available?

      ElasticAPM.set_user(user)
    end

    # Add custom context to the current transaction
    # If called several times during a transaction the custom context will be destructively merged with merge!.
    # before_action do
    #   ElasticAPM.set_custom_context(company: current_user.company.to_h)
    # end
    # @param context [Hash] Context information. Can be nested.
    # @return [Hash, nil] Returns the context that was set or nil if APM is disabled
    def set_custom_context(context)
      return unless apm_available?

      ElasticAPM.set_custom_context(context)
    end

    # Report an error to APM
    # @param exception [Exception] The exception to report
    # @param handled [Boolean] Whether the exception was handled
    def report_error(exception, handled: true)
      return unless apm_available?

      ElasticAPM.report(exception, handled: handled)
    end

    # Get the current transaction
    # Returns the current ElasticAPM::Transaction or nil.
    # @return [Object, nil] Current transaction or nil if no transaction or APM is disabled
    def current_transaction
      return unless apm_available?

      ElasticAPM.current_transaction
    end

    # Check if ElasticAPM is available and enabled
    # @return [Boolean] true if ElasticAPM is available and enabled
    def apm_available?
      defined?(ElasticAPM) && ElasticAPM.agent&.config&.enabled
    end
  end
end
