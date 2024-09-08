require 'test_helper'
require 'mocha/minitest'

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class LoggerTest < ActiveSupport::TestCase
    setup do
      @rails_logger = mock('rails_logger')
      DynamicLinks::Logger.stubs(:instance).returns(@rails_logger)
    end

    def teardown
      mocha_teardown
      DynamicLinks.configuration.enable_logging = DynamicLinks::Configuration::DEFAULT_ENABLE_LOGGING 
    end

    test 'log_info should log an info message when logging is enabled' do
      message = 'Test info message'
      @rails_logger.expects(:info).with(message)

      DynamicLinks::Logger.log_info(message)
    end

    test 'log_error should log an error message when logging is enabled' do
      message = 'Test error message'
      @rails_logger.expects(:error).with(message)

      DynamicLinks::Logger.log_error(message)
    end

    test 'log_info should not log when logging is disabled' do
      DynamicLinks.configuration.enable_logging = false
      message = 'This should not be logged'
      @rails_logger.expects(:info).never

      DynamicLinks::Logger.log_info(message)
    end

    test 'log_error should not log when logging is disabled' do
      DynamicLinks.configuration.enable_logging = false
      message = 'This should not be logged'
      @rails_logger.expects(:error).never

      DynamicLinks::Logger.log_error(message)
    end
  end
end
