# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class HostAuthorizationTest < ActiveSupport::TestCase
    def setup
      @mock_request = mock_request_object
    end

    test 'allows health check endpoints' do
      @mock_request.stubs(:path).returns('/up')
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow health check endpoint'
    end

    test 'allows localhost' do
      @mock_request.stubs(:host).returns('localhost')
      @mock_request.stubs(:host_with_port).returns('localhost:3000')
      @mock_request.stubs(:local?).returns(true)
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow localhost'
    end

    test 'allows 127.0.0.1' do
      @mock_request.stubs(:host).returns('127.0.0.1')
      @mock_request.stubs(:host_with_port).returns('127.0.0.1:3000')
      @mock_request.stubs(:local?).returns(true)
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow 127.0.0.1'
    end

    test 'allows example.org for test environment' do
      @mock_request.stubs(:host).returns('example.org')
      @mock_request.stubs(:host_with_port).returns('example.org')
      @mock_request.stubs(:local?).returns(false)
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow example.org'
    end

    test 'allows local hosts when request is local' do
      @mock_request.stubs(:host).returns('custom.local')
      @mock_request.stubs(:host_with_port).returns('custom.local:3000')
      @mock_request.stubs(:local?).returns(true)
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow local request hosts'
    end

    test 'allows registered client hostname' do
      client = DynamicLinks::Client.create!(
        name: 'Test Client',
        api_key: 'test_key',
        hostname: 'test.example.com',
        scheme: 'https'
      )

      @mock_request.stubs(:host).returns('test.example.com')
      @mock_request.stubs(:host_with_port).returns('test.example.com:3000')
      @mock_request.stubs(:local?).returns(false)
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow registered client hostname'
      
      client.destroy
    end

    test 'allows registered client hostname with port' do
      client = DynamicLinks::Client.create!(
        name: 'Test Client',
        api_key: 'test_key',
        hostname: 'test.example.com',
        scheme: 'https'
      )

      @mock_request.stubs(:host).returns('test.example.com')
      @mock_request.stubs(:host_with_port).returns('test.example.com:8080')
      @mock_request.stubs(:local?).returns(false)
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow registered client hostname with port'
      
      client.destroy
    end

    test 'rejects unregistered hostname' do
      @mock_request.stubs(:host).returns('evil.hacker.com')
      @mock_request.stubs(:host_with_port).returns('evil.hacker.com')
      @mock_request.stubs(:local?).returns(false)
      
      refute HostAuthorization.allowed?(@mock_request), 'Should reject unregistered hostname'
    end

    test 'allows request when database is not available' do
      @mock_request.stubs(:host).returns('unknown.example.com')
      @mock_request.stubs(:host_with_port).returns('unknown.example.com')
      @mock_request.stubs(:local?).returns(false)
      
      # Mock database connection error
      DynamicLinks::Client.stubs(:exists?).raises(ActiveRecord::ConnectionNotEstablished.new('Database not available'))
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow request when database is not available'
    end

    test 'allows request when table does not exist' do
      @mock_request.stubs(:host).returns('unknown.example.com')
      @mock_request.stubs(:host_with_port).returns('unknown.example.com')
      @mock_request.stubs(:local?).returns(false)
      
      # Mock table not found error
      DynamicLinks::Client.stubs(:exists?).raises(ActiveRecord::StatementInvalid.new('Table does not exist'))
      
      assert HostAuthorization.allowed?(@mock_request), 'Should allow request when table does not exist'
    end

    test 'configure! sets development host authorization' do
      Rails.stubs(:env).returns(ActiveSupport::StringInquirer.new('development'))
      
      hosts_mock = mock('hosts_array')
      hosts_mock.expects(:clear).once
      
      config = mock('config')
      config.expects(:hosts).twice.returns(hosts_mock)
      config.expects(:host_authorization=).once
      
      HostAuthorization.configure!(config)
    end

    test 'configure! sets host authorization in production' do
      Rails.stubs(:env).returns(ActiveSupport::StringInquirer.new('production'))
      config = mock('config')
      config.expects(:host_authorization=).once
      
      HostAuthorization.configure!(config)
    end

    test 'configure! sets host authorization in test' do
      Rails.stubs(:env).returns(ActiveSupport::StringInquirer.new('test'))
      config = mock('config')
      config.expects(:host_authorization=).once
      
      HostAuthorization.configure!(config)
    end

    private

    def mock_request_object
      request = mock('request')
      request.stubs(:path).returns('/some-path')
      request.stubs(:host).returns('example.com')
      request.stubs(:host_with_port).returns('example.com:3000')
      request.stubs(:local?).returns(false)
      request
    end
  end
end
