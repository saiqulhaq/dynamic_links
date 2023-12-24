require "test_helper"

class DynamicLinks::V1::ShortLinksControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    post '/v1/shortLinks', params: { url: 'https://example.com' }
    expected_body_response = {
      shortLink: 'http://link',
      previewLink: 'http://xxx.goo.gl/foo?preview',
      warning: [{
        'warningCode' => 'UNRECOGNIZED_PARAM',
        'warningMessage' => '...'
      }]
    }.as_json
    assert_response :success
    content_type = "application/json; charset=utf-8"
    assert_equal content_type, @response.content_type
    assert_equal expected_body_response, JSON.parse(response.body)
  end
end
