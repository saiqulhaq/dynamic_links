# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  module ShorteningStrategies
    class MockStrategyTest < ActiveSupport::TestCase
      def setup
        @url_shortener = DynamicLinks::ShorteningStrategies::MockStrategy.new
      end

      test 'raise shorten method not implemented' do
        url = 'https://example.com'
        short_url = @url_shortener.shorten(url)
        assert_equal url, short_url
      end

      test 'is not generates a new shortened URL' do
        assert_equal @url_shortener.always_growing?, false
      end
    end
  end
end
