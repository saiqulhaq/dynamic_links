# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Include performance tracking if ElasticAPM is enabled
  include PerformanceTracking
  
  # Include OAuth2-Proxy authentication
  include Oauth2ProxyAuthentication
end
