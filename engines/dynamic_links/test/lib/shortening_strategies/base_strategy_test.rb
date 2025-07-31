# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  module ShorteningStrategies
    class BaseStrategyTest < ActiveSupport::TestCase
      def setup
        @url_shortener = DynamicLinks::ShorteningStrategies::BaseStrategy.new
      end

      test 'raise shorten method not implemented' do
        url = 'https://example.com'
        assert_raises(NotImplementedError, 'You must implement the shorten method') { @url_shortener.shorten(url) }
      end

      test 'is not generates a new shortened URL' do
        assert_equal @url_shortener.always_growing?, false
      end
    end
  end
end
