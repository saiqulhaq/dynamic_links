require "test_helper"

# @author Saiqul Haq <saiqulhaq@gmail.com>
class DynamicLinks::ValidatorTest < ActiveSupport::TestCase
  test "valid_url? returns true for a valid HTTP URL" do
    assert DynamicLinks::Validator.valid_url?("http://example.com")
  end

  test "valid_url? returns true for a valid HTTPS URL" do
    assert DynamicLinks::Validator.valid_url?("https://example.com")
  end

  test "valid_url? returns false for an invalid URL" do
    refute DynamicLinks::Validator.valid_url?("invalid_url")
  end

  test "valid_url? returns false for a malformed URL" do
    refute DynamicLinks::Validator.valid_url?("http://example. com") # Space in the URL
  end

  test "valid_url? returns false for a non-http/https URL" do
    refute DynamicLinks::Validator.valid_url?("ftp://example.com")
  end
end

