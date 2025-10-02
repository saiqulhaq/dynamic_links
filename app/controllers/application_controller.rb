# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  # Include performance tracking if ElasticAPM is enabled
  include PerformanceTracking
end
