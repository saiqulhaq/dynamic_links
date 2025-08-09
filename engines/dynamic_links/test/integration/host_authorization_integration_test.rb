# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class HostAuthorizationIntegrationTest < ActionDispatch::IntegrationTest
    def setup
      # Create test clients with valid hostnames (no ports in hostname field)
      @demo_client = DynamicLinks::Client.create!(
        name: 'Demo Client',
        api_key: 'demo_key',
        hostname: 'short.demo.local',
        scheme: 'https'
      )

      @enterprise_client = DynamicLinks::Client.create!(
        name: 'Enterprise Client', 
        api_key: 'enterprise_key',
        hostname: 'go.enterprise.local',
        scheme: 'https'
      )

      # Create test URLs
      @demo_url = DynamicLinks::ShortenedUrl.create!(
        url: 'https://www.example.com/test',
        short_url: 'test123',
        client: @demo_client
      )

      @enterprise_url = DynamicLinks::ShortenedUrl.create!(
        url: 'https://www.enterprise.com/report',
        short_url: 'report',
        client: @enterprise_client
      )
    end

    def teardown
      @demo_client&.destroy
      @enterprise_client&.destroy
      @demo_url&.destroy
      @enterprise_url&.destroy
    end

    # Test that the host authorization logic correctly identifies allowed requests
    # Note: These tests verify the logic itself rather than Rails' host authorization
    # enforcement, since in test environment all hosts are typically allowed

    test 'host authorization logic allows localhost' do
      request = create_mock_request('/up', 'localhost')
      assert DynamicLinks::HostAuthorization.allowed?(request), 'Should allow localhost'
    end

    test 'host authorization logic allows 127.0.0.1' do
      request = create_mock_request('/test', '127.0.0.1')
      assert DynamicLinks::HostAuthorization.allowed?(request), 'Should allow 127.0.0.1'
    end

    test 'host authorization logic allows example.org' do
      request = create_mock_request('/test', 'example.org')
      assert DynamicLinks::HostAuthorization.allowed?(request), 'Should allow example.org'
    end

    test 'host authorization logic allows health check endpoint from any host' do
      request = create_mock_request('/up', 'evil.hacker.com')
      assert DynamicLinks::HostAuthorization.allowed?(request), 'Should allow health check from any host'
    end

    test 'host authorization logic allows registered client hostname' do
      request = create_mock_request('/test123', 'short.demo.local')
      assert DynamicLinks::HostAuthorization.allowed?(request), 'Should allow registered client hostname'
    end

    test 'host authorization logic allows registered client hostname with port' do
      request = create_mock_request('/report', 'go.enterprise.local', 'go.enterprise.local:8080')
      assert DynamicLinks::HostAuthorization.allowed?(request), 'Should allow registered client hostname with port'
    end

    test 'host authorization logic allows requests when client hostname matches without port' do
      request = create_mock_request('/report', 'go.enterprise.local', 'go.enterprise.local:3000')
      assert DynamicLinks::HostAuthorization.allowed?(request), 'Should allow requests when hostname matches without port'
    end

    test 'host authorization logic rejects unregistered hostname' do
      request = create_mock_request('/test123', 'evil.hacker.com')
      refute DynamicLinks::HostAuthorization.allowed?(request), 'Should reject unregistered hostname'
    end

    test 'host authorization logic rejects partial hostname matches' do
      # Create client with 'example.com', test 'sub.example.com' 
      client = DynamicLinks::Client.create!(
        name: 'Example Client',
        api_key: 'example_key', 
        hostname: 'example.com',
        scheme: 'https'
      )

      request = create_mock_request('/test', 'sub.example.com')
      refute DynamicLinks::HostAuthorization.allowed?(request), 'Should reject partial hostname matches'

      client.destroy
    end

    # Test actual HTTP behavior in test environment
    # Note: In test environment, Rails typically allows all hosts, so these test the URL resolution

    test 'allows requests to registered client URLs' do
      get "/#{@demo_url.short_url}", headers: { 'Host' => 'short.demo.local' }
      assert_response :redirect, 'Should allow requests to registered client hostname'
      assert_redirected_to @demo_url.url
    end

    test 'allows requests with port numbers' do
      get "/#{@enterprise_url.short_url}", headers: { 'Host' => 'go.enterprise.local:8080' }
      assert_response :redirect, 'Should allow requests to registered client hostname with port'
      assert_redirected_to @enterprise_url.url
    end

    test 'allows multiple clients with different hostnames' do
      # Test that both clients work independently
      get "/#{@demo_url.short_url}", headers: { 'Host' => 'short.demo.local' }
      assert_response :redirect
      assert_redirected_to @demo_url.url

      get "/#{@enterprise_url.short_url}", headers: { 'Host' => 'go.enterprise.local:8080' }
      assert_response :redirect  
      assert_redirected_to @enterprise_url.url
    end

    test 'returns 404 for URLs that do not exist for the hostname' do
      # Ensure fallback mode is disabled for this test
      original_fallback = DynamicLinks.configuration.enable_fallback_mode
      original_firebase = DynamicLinks.configuration.firebase_host
      DynamicLinks.configuration.enable_fallback_mode = false
      DynamicLinks.configuration.firebase_host = ''
      
      begin
        # Request a URL that doesn't exist at all
        get "/nonexistent", headers: { 'Host' => 'go.enterprise.local' }
        assert_response :not_found, 'Should return 404 for URLs that do not exist for the client'
      ensure
        DynamicLinks.configuration.enable_fallback_mode = original_fallback
        DynamicLinks.configuration.firebase_host = original_firebase
      end
    end

    test 'host authorization handles database connection errors gracefully' do
      # Mock database connection error
      DynamicLinks::Client.stubs(:exists?).raises(ActiveRecord::ConnectionNotEstablished.new('Database not available'))
      
      request = create_mock_request('/test', 'unknown.example.com')
      assert DynamicLinks::HostAuthorization.allowed?(request), 'Should allow request when database is not available'
      
      DynamicLinks::Client.unstub(:exists?)
    end

    private

    def create_mock_request(path, host, host_with_port = nil)
      request = mock('request')
      request.stubs(:path).returns(path)
      request.stubs(:host).returns(host)
      request.stubs(:host_with_port).returns(host_with_port || host)
      request.stubs(:local?).returns(['localhost', '127.0.0.1', '0.0.0.0'].include?(host))
      request
    end
  end
end
