require "test_helper"

class DynamicLinks::V1::ShortLinksControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    expected_short_link = 'shortened_url'
    DynamicLinks.stub :shorten_url, expected_short_link do
      post '/v1/shortLinks', params: { url: 'https://example.com' }
      expected_body_response = {
        shortLink: expected_short_link,
        previewLink: "#{expected_short_link}?preview=true",
        warning: []
      }.as_json
      assert_response :success
      content_type = "application/json; charset=utf-8"
      assert_equal content_type, @response.content_type
      assert_equal expected_body_response, JSON.parse(response.body)
    end
  end
end
