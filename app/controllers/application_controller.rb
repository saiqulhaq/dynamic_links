class ApplicationController < ActionController::Base
  # Include performance tracking if ElasticAPM is enabled
  include PerformanceTracking
end
