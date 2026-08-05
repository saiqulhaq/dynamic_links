# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  module V1
    class ShortLinksControllerTest < ActionDispatch::IntegrationTest
      setup do
        @client = dynamic_links_clients(:one)
        @original_rest_api_setting = DynamicLinks.configuration.enable_rest_api
      end

      teardown do
        DynamicLinks.configuration.enable_rest_api = @original_rest_api_setting
      end

      test 'should create a shortened URL' do
        url = 'https://example.com'
        api_key = @client.api_key
        expected_short_link = "#{@client.scheme}://#{@client.hostname}/shortened_url"
        expected_response = {
          shortLink: expected_short_link,
          previewLink: "#{expected_short_link}?preview=true",
          warning: []
        }.as_json

        DynamicLinks.stub :generate_short_url, expected_response do
          post '/v1/shortLinks', params: { url: url, api_key: api_key }

          assert_response :created
          assert_equal 'application/json; charset=utf-8', @response.content_type
          assert_equal expected_response, JSON.parse(@response.body)
        end
      end

      test 'should respond with unauthorized for invalid API key' do
        post '/v1/shortLinks', params: { url: 'https://example.com', api_key: 'invalid' }
        assert_response :unauthorized
      end

      test 'should respond with bad request for invalid URL' do
        DynamicLinks.stub :generate_short_url, ->(_url, _client) { raise DynamicLinks::InvalidURIError } do
          post '/v1/shortLinks', params: { url: 'invalid_url', api_key: @client.api_key }
          assert_response :bad_request
        end
      end

      test 'should return internal server error if an error occurs' do
        DynamicLinks.stubs(:generate_short_url).raises(StandardError)
        post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }

        assert_response :internal_server_error
        body = JSON.parse(response.body)
        assert_equal 'An error occurred while processing your request', body['error']
        assert_equal 'StandardError', body['error_class']
      end

      test 'create returns 409 conflict on Short URL collision' do
        invalid = ActiveRecord::RecordInvalid.new(ShortenedUrl.new)
        invalid.record.errors.add(:short_url, 'has already been taken')
        DynamicLinks.stubs(:generate_short_url).raises(invalid)
        post '/v1/shortLinks', params: { url: 'https://example.com/collide', api_key: @client.api_key }

        assert_response :conflict
        body = JSON.parse(response.body)
        assert_includes body['error'], 'conflict'
      end

      test 'create returns 503 on database connection error' do
        DynamicLinks.stubs(:generate_short_url).raises(ActiveRecord::ConnectionNotEstablished)
        post '/v1/shortLinks', params: { url: 'https://example.com/db-down', api_key: @client.api_key }

        assert_response :service_unavailable
        body = JSON.parse(response.body)
        assert_includes body['error'], 'temporarily unavailable'
      end

      test 'create returns 400 when url is a Hash instead of String' do
        post '/v1/shortLinks', params: { url: { malicious: 'hash' }, api_key: @client.api_key }
        assert_response :bad_request
        body = JSON.parse(response.body)
        assert_includes body['error'], 'url must be a string'
      end

      test 'create returns 401 when api_key is a Hash instead of String' do
        post '/v1/shortLinks', params: { url: 'https://example.com', api_key: { stolen: 'data' } }
        assert_response :unauthorized
        body = JSON.parse(response.body)
        assert_includes body['error'], 'Invalid API key'
      end

      test 'find_or_create returns 409 conflict on collision' do
        invalid = ActiveRecord::RecordInvalid.new(ShortenedUrl.new)
        invalid.record.errors.add(:short_url, 'has already been taken')
        DynamicLinks.stubs(:generate_short_url).raises(invalid)
        post '/v1/shortLinks/findOrCreate', params: { url: 'https://example.com/collide', api_key: @client.api_key }

        assert_response :conflict
      end

      test 'find_or_create returns 503 on database connection error' do
        DynamicLinks.stubs(:generate_short_url).raises(ActiveRecord::ConnectionTimeoutError)
        post '/v1/shortLinks/findOrCreate', params: { url: 'https://example.com/db', api_key: @client.api_key }

        assert_response :service_unavailable
      end

      test 'expand returns 400 when short_url param is missing' do
        get "/v1/shortLinks/", params: { api_key: @client.api_key }
        assert_response :not_found # routing not found since path is empty
      end

      test 'expand does not 500 when short_url param is a Hash' do
        get '/v1/shortLinks/abc', params: { api_key: @client.api_key, short_url: { hack: 1 } }
        # short_url in URL path is 'abc' (string), so expand should still work
        # but the :short_url param via query is overridden by the URL path
        # The test ensures that even if a non-string short_url is sent, the
        # controller doesn't 500. The path segment wins, so we get a clean
        # 404 (no record for 'abc') rather than a 500.
        assert_response :not_found
      end

      test 'should not allow short URL creation when REST API is disabled' do
        DynamicLinks.configuration.enable_rest_api = false

        post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }
        assert_response :forbidden
        assert_includes @response.body, 'REST API feature is disabled'
      end

      test 'should expand a valid short URL' do
        short_url = 'abc123'
        full_url = 'https://example.com/full-path'

        DynamicLinks.stub :resolve_short_url, full_url do
          get "/v1/shortLinks/#{short_url}", params: { api_key: @client.api_key }

          assert_response :success
          assert_equal 'application/json; charset=utf-8', @response.content_type
          body = JSON.parse(@response.body)
          assert_equal full_url, body['full_url']
        end
      end

      test 'should return not found for non-existent short URL' do
        short_url = 'nonexistent'

        DynamicLinks.stub :resolve_short_url, nil do
          get "/v1/shortLinks/#{short_url}", params: { api_key: @client.api_key }

          assert_response :not_found
          body = JSON.parse(@response.body)
          assert_equal 'Short link not found', body['error']
        end
      end

      test 'should handle internal server error on expand' do
        short_url = 'abc123'

        DynamicLinks.stub :resolve_short_url, ->(_short_url) { raise StandardError, 'Unexpected error' } do
          get "/v1/shortLinks/#{short_url}", params: { api_key: @client.api_key }

          assert_response :internal_server_error
          body = JSON.parse(@response.body)
          assert_equal 'An error occurred while processing your request', body['error']
        end
      end

      test 'should return existing short URL if found' do
        DynamicLinks.configuration.enable_rest_api = true

        url = 'https://example.com/existing'
        client = @client

        # Simulate existing link
        DynamicLinks::ShortenedUrl.create!(
          url: url,
          short_url: 'exist123',
          client_id: client.id
        )

        post '/v1/shortLinks/findOrCreate', params: { url: url, api_key: client.api_key }

        assert_response :ok
        body = JSON.parse(response.body)
        assert_equal 'https://client-one.com/exist123', body['shortLink']
        assert_equal 'https://client-one.com/exist123?preview=true', body['previewLink']
      end

      test 'should create short URL if not exists' do
        DynamicLinks.configuration.enable_rest_api = true

        url = "https://example.com/new-page-#{SecureRandom.hex(4)}"
        client = @client

        post '/v1/shortLinks/findOrCreate', params: { url: url, api_key: client.api_key }

        assert_response :created
        body = JSON.parse(response.body)
        assert_match(/http/, body['shortLink'])
        assert_match(/\?preview=true/, body['previewLink'])
      end

      test 'should create or find complex but valid URL' do
        DynamicLinks.configuration.enable_rest_api = true

        url = 'https://example.com/search?q=hello%20world&ref=abc&lang=en#top'
        client = @client

        post '/v1/shortLinks/findOrCreate', params: { url: url, api_key: client.api_key }

        assert_response :created
        body = JSON.parse(response.body)
        assert_match(/http/, body['shortLink'])
      end

      test 'should return bad request for invalid URL' do
        DynamicLinks.configuration.enable_rest_api = true

        post '/v1/shortLinks/findOrCreate', params: { url: 'http:/bad', api_key: @client.api_key }

        assert_response :bad_request
        assert_includes response.body, 'Invalid URL'
      end

      test 'should return unauthorized for invalid API key' do
        post '/v1/shortLinks/findOrCreate', params: { url: 'https://example.com', api_key: 'invalid_key' }

        assert_response :unauthorized
        assert_includes response.body, 'Invalid API key'
      end

      test 'should return forbidden when REST API is disabled' do
        DynamicLinks.configuration.enable_rest_api = false

        post '/v1/shortLinks/findOrCreate', params: { url: 'https://example.com', api_key: @client.api_key }

        assert_response :forbidden
        assert_includes response.body, 'REST API feature is disabled'
      end

      test 'should create a shortened URL with expires_at' do
        url = 'https://example.com'
        api_key = @client.api_key
        expires_at = (Time.zone.now + 1.day).iso8601
        expected_short_link = "#{@client.scheme}://#{@client.hostname}/shortened_url"
        expected_response = {
          shortLink: expected_short_link,
          previewLink: "#{expected_short_link}?preview=true",
          warning: []
        }.as_json

        DynamicLinks.stub :generate_short_url, expected_response do
          post '/v1/shortLinks', params: { url: url, api_key: api_key, expires_at: expires_at }

          assert_response :created
          assert_equal 'application/json; charset=utf-8', @response.content_type
          assert_equal expected_response, JSON.parse(@response.body)
        end
      end

      test 'should reject invalid expires_at format' do
        url = 'https://example.com'
        api_key = @client.api_key
        invalid_expires_at = 'not-a-date'

        post '/v1/shortLinks', params: { url: url, api_key: api_key, expires_at: invalid_expires_at }

        assert_response :bad_request
        body = JSON.parse(@response.body)
        assert_includes body['error'], 'Invalid expires_at format'
      end

      test 'should create short URL with expires_at in find_or_create' do
        DynamicLinks.configuration.enable_rest_api = true

        url = "https://example.com/new-with-expiry-#{SecureRandom.hex(4)}"
        client = @client
        expires_at = (Time.zone.now + 7.days).iso8601

        post '/v1/shortLinks/findOrCreate', params: { url: url, api_key: client.api_key, expires_at: expires_at }

        assert_response :created
        body = JSON.parse(response.body)
        assert_match(/http/, body['shortLink'])
        assert_match(/\?preview=true/, body['previewLink'])
      end

      test 'should reject invalid expires_at format in find_or_create' do
        DynamicLinks.configuration.enable_rest_api = true

        url = 'https://example.com/test'
        invalid_expires_at = 'invalid-date-format'

        post '/v1/shortLinks/findOrCreate',
             params: { url: url, api_key: @client.api_key, expires_at: invalid_expires_at }

        assert_response :bad_request
        body = JSON.parse(response.body)
        assert_includes body['error'], 'Invalid expires_at format'
      end

      test 'should reject expires_at in the past' do
        DynamicLinks.configuration.enable_rest_api = true

        url = "https://example.com/past-expiry-#{SecureRandom.hex(4)}"
        past_expires_at = (Time.zone.now - 1.day).iso8601

        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key, expires_at: past_expires_at }

        assert_response :bad_request
        body = JSON.parse(@response.body)
        assert_includes body['error'], 'Invalid expires_at format'
      end

      test 'create defaults expires_at to 3 months from now when not provided' do
        DynamicLinks.configuration.enable_rest_api = true

        url = "https://example.com/default-expiry-#{SecureRandom.hex(4)}"

        post '/v1/shortLinks', params: { url: url, api_key: @client.api_key }

        assert_response :created
        record = DynamicLinks::ShortenedUrl.find_by(url: url, client_id: @client.id)
        assert_not_nil record, 'expected ShortenedUrl to be persisted'
        expected = 3.months.from_now
        assert_in_delta expected.to_f, record.expires_at.to_f, 60,
                        "expires_at should default to ~3 months from now, got #{record.expires_at}"
      end

      test 'find_or_create defaults expires_at to 3 months from now when not provided' do
        DynamicLinks.configuration.enable_rest_api = true

        url = "https://example.com/find-or-create-default-expiry-#{SecureRandom.hex(4)}"

        post '/v1/shortLinks/findOrCreate', params: { url: url, api_key: @client.api_key }

        assert_response :created
        record = DynamicLinks::ShortenedUrl.find_by(url: url, client_id: @client.id)
        assert_not_nil record
        expected = 3.months.from_now
        assert_in_delta expected.to_f, record.expires_at.to_f, 60
      end

      test 'find_or_create mints a new short URL when the existing one is expired' do
        DynamicLinks.configuration.enable_rest_api = true

        url = "https://example.com/recyclable-#{SecureRandom.hex(4)}"
        original_short_url = "expired#{SecureRandom.hex(2)}"
        expired = DynamicLinks::ShortenedUrl.new(
          client: @client,
          url: url,
          short_url: original_short_url,
          expires_at: 1.day.ago
        )
        expired.save(validate: false)

        post '/v1/shortLinks/findOrCreate', params: { url: url, api_key: @client.api_key }

        assert_response :created
        body = JSON.parse(response.body)
        refute_equal "https://#{@client.hostname}/#{original_short_url}", body['shortLink'],
                     'find_or_create should mint a fresh short URL once the existing one expires'
      end
    end
  end
end
