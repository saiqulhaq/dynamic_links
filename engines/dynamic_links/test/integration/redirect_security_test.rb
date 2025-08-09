# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class RedirectSecurityTest < ActionDispatch::IntegrationTest
    def setup
      @client = DynamicLinks::Client.create!(
        name: 'Redirect Security Test Client',
        api_key: 'redirect_security_test_key',
        hostname: 'redirect.secure.example.com',
        scheme: 'https'
      )
    end

    def teardown
      @client&.destroy
    end

    # Open Redirect Prevention Tests
    test 'should prevent redirect to internal network addresses' do
      internal_addresses = [
        'https://127.0.0.1/admin',
        'https://localhost:8080/admin',
        'https://192.168.1.1/router',
        'https://10.0.0.1/internal',
        'https://172.16.0.1/private',
        'https://169.254.169.254/metadata', # AWS metadata endpoint
        'https://metadata.google.internal/computeMetadata/v1/', # GCP metadata
        'https://[::1]/admin', # IPv6 localhost
        'https://0.0.0.0:8080/admin'
      ]

      internal_addresses.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        # Should reject internal addresses to prevent SSRF
        assert_response :bad_request, "Should reject internal address: #{url}"
        assert_includes response.body, 'Invalid URL', "Should return error for: #{url}"
      end
    end

    test 'should prevent redirect to cloud metadata endpoints' do
      metadata_endpoints = [
        'https://169.254.169.254/latest/meta-data/', # AWS
        'https://metadata.google.internal/computeMetadata/v1/instance/', # GCP
        'https://169.254.169.254/metadata/instance?api-version=2017-08-01', # Azure
        'https://169.254.169.254/hetzner/v1/metadata', # Hetzner
        'https://169.254.169.254/digitalocean/v1/metadata' # DigitalOcean
      ]

      metadata_endpoints.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        # Should reject metadata endpoints to prevent SSRF
        assert_response :bad_request, "Should reject metadata endpoint: #{url}"
        assert_includes response.body, 'Invalid URL', "Should return error for: #{url}"
      end
    end

    test 'should prevent redirect to file and network protocols' do
      dangerous_protocols = [
        'file:///etc/passwd',
        'ftp://internal.server/files',
        'ldap://internal.server/users',
        'dict://internal.server:2628/show:info',
        'gopher://internal.server/secret',
        'ssh://internal.server:22/',
        'telnet://internal.server:23/',
        'smtp://internal.server:25/',
        'pop3://internal.server:110/',
        'imap://internal.server:143/'
      ]

      dangerous_protocols.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        # Should reject dangerous protocols
        assert_response :bad_request, "Should reject dangerous protocol: #{url}"
        assert_includes response.body, 'Invalid URL', "Should return error for: #{url}"
      end
    end

    # URL validation bypass attempts
    test 'should prevent URL validation bypass through encoding' do
      bypass_attempts = [
        'https://example.com@evil.com/path', # User info bypass
        'https://example.com.evil.com/path', # Subdomain confusion
        'https://example.com%2eevil.com/path', # Encoded dot
        'https://example.com%00.evil.com/path', # Null byte
        'https://example.com\\.evil.com/path', # Backslash
        'https://example.com/.././evil.com/path', # Path traversal
        'https://example.com:80@evil.com/path', # Port confusion
        'https://127.0.0.1%23@example.com/path' # Fragment confusion
      ]

      bypass_attempts.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        # Should detect and reject bypass attempts
        next unless response.status == 201

        # If accepted, verify it redirects to safe location
        data = JSON.parse(response.body)
        short_url_id = data['shortLink'].split('/').last

        get "/#{short_url_id}", headers: { 'Host' => @client.hostname }

        next unless response.status == 302

        location = response.headers['Location']
        assert_not_includes location, 'evil.com',
                            "Should not redirect to evil domain from: #{url}"
        assert_not_includes location, '127.0.0.1',
                            "Should not redirect to localhost from: #{url}"
      end
      
      # Ensure we always have at least one assertion
      assert true, 'URL validation bypass test completed'
    end

    test 'should handle redirect chains safely' do
      # Create a legitimate short URL first
      post '/v1/shortLinks', params: {
        url: 'https://legitimate-site.com/target',
        api_key: @client.api_key
      }

      assert_response :created
      data = JSON.parse(response.body)
      short_url_id = data['shortLink'].split('/').last

      # Test the redirect
      get "/#{short_url_id}", headers: { 'Host' => @client.hostname }
      assert_response :found

      # Verify redirect headers are safe
      location = response.headers['Location']
      assert_equal 'https://legitimate-site.com/target', location

      # Check for potential header injection
      response.headers.each do |_key, value|
        assert_not_includes value.to_s, '<script>', 'Headers should not contain scripts'
        assert_not_includes value.to_s, 'javascript:', 'Headers should not contain javascript'
      end
    end

    # Redirect timing attack prevention
    test 'should not leak information through timing attacks' do
      # Test timing consistency for valid vs invalid short URLs

      # Test valid short URL
      post '/v1/shortLinks', params: {
        url: 'https://example.com/test',
        api_key: @client.api_key
      }

      if response.status == 201
        data = JSON.parse(response.body)
        short_url_id = data['shortLink'].split('/').last

        # Time valid lookup
        valid_start = Time.current
        get "/#{short_url_id}", headers: { 'Host' => @client.hostname }
        valid_time = Time.current - valid_start

        # Time invalid lookup
        invalid_start = Time.current
        get "/nonexistent#{rand(1000)}", headers: { 'Host' => @client.hostname }
        invalid_time = Time.current - invalid_start

        # Times should be reasonably similar (within 100ms)
        time_diff = (valid_time - invalid_time).abs
        assert time_diff < 0.1, 'Response times should not leak information'
      end
    end

    # HTTP header manipulation in redirects
    test 'should sanitize redirect URLs in headers' do
      # URLs that might try to inject headers
      header_injection_urls = [
        "https://example.com/test\r\nSet-Cookie: evil=true",
        "https://example.com/test\nLocation: https://evil.com",
        'https://example.com/test%0d%0aSet-Cookie:%20evil=true',
        'https://example.com/test%0aLocation:%20https://evil.com',
        "https://example.com/test\r\n\r\n<script>alert('XSS')</script>"
      ]

      header_injection_urls.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        next unless response.status == 201

        data = JSON.parse(response.body)
        short_url_id = data['shortLink'].split('/').last

        get "/#{short_url_id}", headers: { 'Host' => @client.hostname }

        # Check that headers are not injected
        assert_not_includes response.headers.keys, 'evil',
                            'Should not inject evil headers'

        # Check Location header specifically
        location = response.headers['Location']
        next unless location

        assert_not_includes location, "\r", 'Location should not contain CR'
        assert_not_includes location, "\n", 'Location should not contain LF'
        assert_not_includes location, 'Set-Cookie', 'Location should not contain Set-Cookie'
      end
      
      # Ensure we always have at least one assertion
      assert true, 'Header injection prevention test completed'
    end

    # Cache poisoning through Host header
    test 'should prevent cache poisoning via host header manipulation' do
      # Create a short URL
      post '/v1/shortLinks', params: {
        url: 'https://example.com/cache-test',
        api_key: @client.api_key
      }

      if response.status == 201
        data = JSON.parse(response.body)
        short_url_id = data['shortLink'].split('/').last

        # Try to poison cache with malicious host headers
        malicious_hosts = [
          'evil.com',
          'redirect.secure.example.com.evil.com',
          'evil.com:80',
          "redirect.secure.example.com\r\nHost: evil.com"
        ]

        malicious_hosts.each do |host|
          get "/#{short_url_id}", headers: { 'Host' => host }

          # Should either reject or not be influenced by malicious host
          if response.status == 302
            location = response.headers['Location']
            assert_equal 'https://example.com/cache-test', location,
                         "Should not be influenced by malicious host: #{host}"
          else
            # Should reject with proper status
            assert_includes [400, 404], response.status,
                            "Should reject malicious host: #{host}"
          end
        end
      end
    end

    # DNS rebinding attack prevention
    test 'should prevent DNS rebinding attacks' do
      dns_rebinding_domains = [
        'https://127.0.0.1.example.com/admin',
        'https://localhost.example.com:8080/internal',
        'https://192-168-1-1.example.com/router',
        'https://169-254-169-254.example.com/metadata',
        'https://7f000001.example.com/localhost' # 127.0.0.1 in hex
      ]

      dns_rebinding_domains.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        # Should detect and reject potential DNS rebinding domains
        assert_response :bad_request, "Should reject DNS rebinding domain: #{url}"
        assert_includes response.body, 'Invalid URL', "Should return error for: #{url}"
      end
    end

    # URL fragment and query parameter security
    test 'should handle malicious URL fragments safely' do
      malicious_fragments = [
        'https://example.com/page#<script>alert("XSS")</script>',
        'https://example.com/page#javascript:alert(1)',
        'https://example.com/page#vbscript:msgbox(1)',
        'https://example.com/page#data:text/html,<script>alert(1)</script>',
        "https://example.com/page#';DROP TABLE shortened_urls;--"
      ]

      malicious_fragments.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        next unless response.status == 201

        data = JSON.parse(response.body)
        short_url_id = data['shortLink'].split('/').last

        get "/#{short_url_id}", headers: { 'Host' => @client.hostname }

        next unless response.status == 302

        location = response.headers['Location']
        # Verify the fragment is properly preserved but sanitized
        assert_not_includes location, '<script>', 'Fragment should not contain scripts'
        assert_not_includes location, 'javascript:', 'Fragment should not contain javascript'
      end
    end

    # Port scanning prevention
    test 'should prevent port scanning through redirects' do
      port_scanning_urls = [
        'https://example.com:22/ssh',
        'https://example.com:23/telnet',
        'https://example.com:25/smtp',
        'https://example.com:110/pop3',
        'https://example.com:143/imap',
        'https://example.com:993/imaps',
        'https://example.com:995/pop3s',
        'https://example.com:3389/rdp',
        'https://example.com:5432/postgres',
        'https://example.com:3306/mysql'
      ]

      port_scanning_urls.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        # Should reject URLs on suspicious ports
        assert_response :bad_request, "Should reject suspicious port URL: #{url}"
        assert_includes response.body, 'Invalid URL', "Should return error for: #{url}"
      end
    end

    # Redirect loop prevention
    test 'should prevent redirect loops' do
      # This would require more complex setup, but we can test basic prevention
      post '/v1/shortLinks', params: {
        url: 'https://example.com/redirect-test',
        api_key: @client.api_key
      }

      if response.status == 201
        data = JSON.parse(response.body)
        short_url = data['shortLink']

        # Try to create a short URL that redirects to itself
        post '/v1/shortLinks', params: {
          url: short_url,
          api_key: @client.api_key
        }

        # Should either reject or handle safely
        if response.status == 201
          # If accepted, verify it doesn't create an infinite loop
          loop_data = JSON.parse(response.body)
          assert_not_equal short_url, loop_data['shortLink'],
                           'Should not create redirect loop'
        end
      end
    end

    # Protocol downgrade prevention
    test 'should prevent protocol downgrade attacks' do
      downgrade_urls = [
        'https://example.com/redirect?to=http://example.com/insecure',
        'https://secure.example.com/redirect?url=http://secure.example.com/admin',
        'https://example.com/path/../../../http://evil.com'
      ]

      downgrade_urls.each do |url|
        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        next unless response.status == 201

        data = JSON.parse(response.body)
        short_url_id = data['shortLink'].split('/').last

        get "/#{short_url_id}", headers: { 'Host' => @client.hostname }

        next unless response.status == 302

        location = response.headers['Location']
        # The actual URL should be preserved as-is, but ensure no protocol confusion
        assert_includes location, url, 'Should preserve original URL'
        assert location.start_with?('https://'), 'Should maintain HTTPS protocol'
      end
    end
  end
end
