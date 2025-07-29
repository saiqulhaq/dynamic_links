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
    end

    test 'log_info should log an info message' do
      message = 'Test info message'
      @rails_logger.expects(:info).with(message)

      DynamicLinks::Logger.log_info(message)
    end

    test 'log_error should log an error message' do
      message = 'Test error message'
      @rails_logger.expects(:error).with(message)

      DynamicLinks::Logger.log_error(message)
    end
  end
end
