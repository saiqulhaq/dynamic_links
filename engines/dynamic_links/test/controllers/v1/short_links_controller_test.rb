# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  module V1
    class ShortLinksControllerTest < ActionDispatch::IntegrationTest
      setup do
        @client = dynamic_links_clients(:one)
        @original_rest_api_setting = DynamicLinks.configuration.enable_rest_api
        @original_db_infra_strategy = DynamicLinks.configuration.db_infra_strategy
      end

      teardown do
        DynamicLinks.configuration.enable_rest_api = @original_rest_api_setting
        DynamicLinks.configuration.db_infra_strategy = @original_db_infra_strategy
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

      test 'should return internal server error if multi_tenant block raises an error' do
        DynamicLinks.stubs(:generate_short_url).raises(StandardError)
        post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }

        assert_response :internal_server_error
        assert_equal '{"error":"An error occurred while processing your request"}', response.body
      end

      test 'should not allow short URL creation when REST API is disabled' do
        DynamicLinks.configuration.enable_rest_api = false

        post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }
        assert_response :forbidden
        assert_includes @response.body, 'REST API feature is disabled'
      end

      if defined?(::MultiTenant)
        test 'should use MultiTenant.with when db_infra_strategy is :sharding' do
          DynamicLinks.configuration.db_infra_strategy = :sharding
          ::MultiTenant.expects(:with).with(@client).once
          url = 'https://example.com/'
          api_key = @client.api_key
          post '/v1/shortLinks', params: { url: url, api_key: api_key }
        end

        test 'should not use MultiTenant.with when db_infra_strategy is not :sharding' do
          DynamicLinks.configuration.db_infra_strategy = :standard
          url = 'https://example.com/'
          api_key = @client.api_key
          ::MultiTenant.expects(:with).with(@client).never
          post '/v1/shortLinks', params: { url: url, api_key: api_key }
        end
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
        DynamicLinks.configuration.db_infra_strategy = :standard

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
        DynamicLinks.configuration.db_infra_strategy = :standard

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
        DynamicLinks.configuration.db_infra_strategy = :standard

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
    end
  end
end
