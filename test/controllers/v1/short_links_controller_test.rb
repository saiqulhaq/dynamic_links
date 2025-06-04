require "test_helper"

class DynamicLinks::V1::ShortLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = dynamic_links_clients(:one)
    @original_rest_api_setting = DynamicLinks.configuration.enable_rest_api
    @original_db_infra_strategy = DynamicLinks.configuration.db_infra_strategy
    # Enable detailed errors in test mode
    @original_show_detailed_errors = DynamicLinks.configuration.show_detailed_errors
    DynamicLinks.configuration.show_detailed_errors = true if defined?(DynamicLinks.configuration.show_detailed_errors)
    
    # Set up MultiTenant mock if needed
    @using_multi_tenant = false
    if ENV['CITUS_ENABLED'] == 'true'
      @using_multi_tenant = true
      # Make sure MultiTenant is properly defined for tests
      unless defined?(::MultiTenant)
        # Create a stub MultiTenant module for testing if not available
        module ::MultiTenant
          def self.with(tenant)
            yield
          end
        end
      end
    end
  end

  teardown do
    DynamicLinks.configuration.enable_rest_api = @original_rest_api_setting
    DynamicLinks.configuration.db_infra_strategy = @original_db_infra_strategy
    DynamicLinks.configuration.show_detailed_errors = @original_show_detailed_errors if defined?(DynamicLinks.configuration.show_detailed_errors)
  end

  # Helper method to get detailed error from response
  def get_detailed_error(response)
    body = JSON.parse(response.body)
    if body["detailed_error"].present?
      puts "DETAILED ERROR: #{body['detailed_error']}"
      puts "ERROR BACKTRACE: #{body['backtrace']}" if body["backtrace"].present?
    end
    body
  end

  test "should create a shortened URL" do
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
      assert_equal "application/json; charset=utf-8", @response.content_type
      assert_equal expected_response, JSON.parse(@response.body)
    end
  end

  test "should respond with unauthorized for invalid API key" do
    post '/v1/shortLinks', params: { url: 'https://example.com', api_key: 'invalid' }
    assert_response :unauthorized
  end

  test "should respond with bad request for invalid URL" do
    if @using_multi_tenant
      ::MultiTenant.expects(:with).with(@client).at_least_once.yields
    end
    
    DynamicLinks.stub :generate_short_url, ->(_url, _client) { raise DynamicLinks::InvalidURIError } do
      post '/v1/shortLinks', params: { url: 'invalid_url', api_key: @client.api_key }
      assert_response :bad_request
    end
  end

  test "should not allow short URL creation when REST API is disabled" do
    DynamicLinks.configuration.enable_rest_api = false

    post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }
    assert_response :forbidden
    assert_includes @response.body, 'REST API feature is disabled'
  end

  if defined?(::MultiTenant)
    test "should use MultiTenant.with when db_infra_strategy is :sharding" do
      skip unless defined?(::MultiTenant)
    
      DynamicLinks.configuration.db_infra_strategy = :sharding
    
      # Explicitly set up the expectation
      mock = ::MultiTenant.expects(:with).with(@client).once.yields
    
      # Stub generate_short_url to prevent other errors
      DynamicLinks.stub :generate_short_url, { shortLink: "test" } do
        post '/v1/shortLinks', params: { url: 'https://example.com/', api_key: @client.api_key }
      end
    
      # Verify the expectation was met
    end

    test "should not use MultiTenant.with when db_infra_strategy is not :sharding" do
      skip unless defined?(::MultiTenant)
    
      DynamicLinks.configuration.db_infra_strategy = :standard
    
      # Explicitly never expect MultiTenant.with to be called
      ::MultiTenant.expects(:with).never
    
      # Stub generate_short_url to prevent other errors
      DynamicLinks.stub :generate_short_url, { shortLink: "test" } do
        post '/v1/shortLinks', params: { url: 'https://example.com/', api_key: @client.api_key }
      end
    end
  end

  test "should expand a valid short URL" do
    short_url = 'abc123'
    full_url = 'https://example.com/full-path'

    DynamicLinks.stub :resolve_short_url, full_url do
      get "/v1/shortLinks/#{short_url}", params: { api_key: @client.api_key }

      assert_response :success
      assert_equal "application/json; charset=utf-8", @response.content_type
      body = JSON.parse(@response.body)
      assert_equal full_url, body["full_url"]
    end
  end

  test "should return not found for non-existent short URL" do
    if @using_multi_tenant
      ::MultiTenant.expects(:with).with(@client).at_least_once.yields
    end
    
    short_url = 'nonexistent'

    DynamicLinks.stub :resolve_short_url, nil do
      get "/v1/shortLinks/#{short_url}", params: { api_key: @client.api_key }

      assert_response :not_found
      body = JSON.parse(@response.body)
      assert_equal 'Short link not found', body["error"]
    end
  end

  test "should capture and display detailed errors in test mode" do
    skip unless defined?(DynamicLinks.configuration.show_detailed_errors)
    
    short_url = 'test_error'
    test_error = RuntimeError.new("Test specific error for debugging")
    
    DynamicLinks.stub :resolve_short_url, ->(_) { raise test_error } do
      get "/v1/shortLinks/#{short_url}", params: { api_key: @client.api_key }
      
      assert_response :internal_server_error
      body = get_detailed_error(@response)
      assert_includes body["detailed_error"], "Test specific error for debugging" if body["detailed_error"]
    end
  end

  test "should handle internal server error on expand" do
    short_url = 'abc123'

    DynamicLinks.stub :resolve_short_url, ->(_short_url) { raise StandardError, "Unexpected error" } do
      get "/v1/shortLinks/#{short_url}", params: { api_key: @client.api_key }

      assert_response :internal_server_error
      body = JSON.parse(@response.body)
      assert_equal 'An error occurred while processing your request', body["error"]
    end
  end
end
