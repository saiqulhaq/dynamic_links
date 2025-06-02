# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require_relative '../test/dummy/config/environment'

ActiveRecord::Migrator.migrations_paths = [File.expand_path('../test/dummy/db/migrate', __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../db/migrate', __dir__)
require 'rails/test_help'
require 'mocha/minitest'
require 'timecop'

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path('fixtures', __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path('fixtures', __dir__) + '/files'
  ActiveSupport::TestCase.fixtures :all
end

# Monkey-patch multi_tenant in tests to just yield directly (bypasses MultiTenant.with)
module DynamicLinks
  module V1
    class ShortLinksController < ApplicationController
      private

      def multi_tenant(_client)
        yield
      end
    end
  end
end
