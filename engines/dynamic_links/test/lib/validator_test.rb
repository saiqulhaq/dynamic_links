# frozen_string_literal: true

require 'test_helper'

# @author Saiqul Haq <saiqulhaq@gmail.com>
module DynamicLinks
  class ValidatorTest < ActiveSupport::TestCase
    test 'valid_url? returns true for a valid HTTP URL' do
      # Create a client for the test hostname
      client = DynamicLinks::Client.create!(
        name: 'Test Client HTTP',
        api_key: 'test_key_http',
        hostname: 'example.com',
        scheme: 'http'
      )

      assert DynamicLinks::Validator.valid_url?('http://example.com')

      # Clean up
      client.destroy!
    end

    test 'valid_url? returns true for a valid HTTPS URL' do
      # Create a client for the test hostname
      client = DynamicLinks::Client.create!(
        name: 'Test Client HTTPS',
        api_key: 'test_key_https',
        hostname: 'example.com',
        scheme: 'https'
      )

      assert DynamicLinks::Validator.valid_url?('https://example.com')

      # Clean up
      client.destroy!
    end

    test 'valid_url? returns false for an invalid URL' do
      refute DynamicLinks::Validator.valid_url?('invalid_url')
    end

    test 'valid_url? returns false for a malformed URL' do
      refute DynamicLinks::Validator.valid_url?('http://example. com') # Space in the URL
    end

    test 'valid_url? returns false for a non-http/https URL' do
      refute DynamicLinks::Validator.valid_url?('ftp://example.com')
    end

    test 'subdomain_confusion? no longer has vulnerable evil.com check' do
      # These URLs should NOT be blocked by subdomain_confusion? anymore
      # The old vulnerable check would incorrectly block these
      refute DynamicLinks::Validator.subdomain_confusion?('example.com') # evil.com not in path/query
      refute DynamicLinks::Validator.subdomain_confusion?('legitimate-site.com') # different domain

      # But these patterns should still be blocked for other reasons
      assert DynamicLinks::Validator.subdomain_confusion?('example.com@evil.com')
      assert DynamicLinks::Validator.subdomain_confusion?('example.com.evil.com')
    end

    test 'allowed_host? works with empty allowlist (backward compatibility)' do
      # Reset configuration
      original_hosts = DynamicLinks.configuration.allowed_redirect_hosts
      DynamicLinks.configuration.allowed_redirect_hosts = []
      
      # Should allow all hosts when allowlist is empty (original behavior)
      assert DynamicLinks::Validator.allowed_host?('example.com')
      assert DynamicLinks::Validator.allowed_host?('any-domain.com')
      assert DynamicLinks::Validator.allowed_host?('untrusted.com')
      
      # Restore original configuration
      DynamicLinks.configuration.allowed_redirect_hosts = original_hosts
    end

    test 'allowed_host? can be configured to check dynamic client hostnames' do
      # This test shows how to enable client hostname checking if desired
      # by configuring specific allowed hosts but having a fallback
      
      # Create test client
      client = DynamicLinks::Client.create!(
        name: 'Test Client',
        api_key: 'test_key',
        hostname: 'client.example.com',
        scheme: 'https'
      )
      
      # When allowlist is empty, any host is allowed (backward compatibility)
      original_hosts = DynamicLinks.configuration.allowed_redirect_hosts
      DynamicLinks.configuration.allowed_redirect_hosts = []
      
      assert DynamicLinks::Validator.allowed_host?('any-domain.com')
      assert DynamicLinks::Validator.allowed_host?('client.example.com')
      
      # Clean up
      client.destroy!
      DynamicLinks.configuration.allowed_redirect_hosts = original_hosts
    end

    test 'allowed_host? enforces allowlist when configured' do
      # Reset configuration
      original_hosts = DynamicLinks.configuration.allowed_redirect_hosts
      DynamicLinks.configuration.allowed_redirect_hosts = ['example.com', 'trusted.org']

      # Should allow exact matches
      assert DynamicLinks::Validator.allowed_host?('example.com')
      assert DynamicLinks::Validator.allowed_host?('trusted.org')

      # Should allow proper subdomains
      assert DynamicLinks::Validator.allowed_host?('www.example.com')
      assert DynamicLinks::Validator.allowed_host?('api.trusted.org')
      assert DynamicLinks::Validator.allowed_host?('deep.sub.example.com')

      # Should block non-allowed hosts
      refute DynamicLinks::Validator.allowed_host?('evil.com')
      refute DynamicLinks::Validator.allowed_host?('malicious.net')

      # Should block subdomain confusion attacks
      refute DynamicLinks::Validator.allowed_host?('example.com.evil.com')
      refute DynamicLinks::Validator.allowed_host?('evil.example.com.attacker.com')

      # Case insensitive matching
      assert DynamicLinks::Validator.allowed_host?('Example.Com')
      assert DynamicLinks::Validator.allowed_host?('WWW.EXAMPLE.COM')

      # Restore original configuration
      DynamicLinks.configuration.allowed_redirect_hosts = original_hosts
    end

    test 'allowed_host? static allowlist behavior when configured' do
      # Reset configuration  
      original_hosts = DynamicLinks.configuration.allowed_redirect_hosts
      DynamicLinks.configuration.allowed_redirect_hosts = ['static.com']
      
      # Should allow static config hosts
      assert DynamicLinks::Validator.allowed_host?('static.com')
      assert DynamicLinks::Validator.allowed_host?('www.static.com')
      
      # Should block hosts not in allowlist when allowlist is configured
      refute DynamicLinks::Validator.allowed_host?('evil.com')
      refute DynamicLinks::Validator.allowed_host?('untrusted.com')
      
      # Restore original configuration
      DynamicLinks.configuration.allowed_redirect_hosts = original_hosts
    end

    test 'valid_url? integrates allowlist checking correctly' do
      # Reset configuration
      original_hosts = DynamicLinks.configuration.allowed_redirect_hosts
      DynamicLinks.configuration.allowed_redirect_hosts = ['safe.com']

      # Should allow URLs from allowed hosts
      assert DynamicLinks::Validator.valid_url?('https://safe.com/path')
      assert DynamicLinks::Validator.valid_url?('https://www.safe.com/path')

      # Should block URLs from non-allowed hosts
      refute DynamicLinks::Validator.valid_url?('https://evil.com/path')
      refute DynamicLinks::Validator.valid_url?('https://malicious.net')

      # Should block subdomain confusion even with valid protocol
      refute DynamicLinks::Validator.valid_url?('https://safe.com.evil.com')

      # Restore original configuration
      DynamicLinks.configuration.allowed_redirect_hosts = original_hosts
    end
  end
end
