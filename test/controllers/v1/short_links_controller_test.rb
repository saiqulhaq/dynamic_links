require "test_helper"

class DynamicLinks::V1::ShortLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = dynamic_links_clients(:one)  # Assuming you have a fixture for DynamicLinks::Client
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
    DynamicLinks.stub :generate_short_url, ->(_url, _client) { raise DynamicLinks::InvalidURIError } do
      post '/v1/shortLinks', params: { url: 'invalid_url', api_key: @client.api_key }
      assert_response :bad_request
    end
  end
end

