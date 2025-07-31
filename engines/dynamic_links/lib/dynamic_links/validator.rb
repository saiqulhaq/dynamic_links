module DynamicLinks
  class Validator
    # Validates if the given URL is a valid HTTP or HTTPS URL
    # @param url [String] The URL to validate
    # @return [Boolean] true if valid, false otherwise
    def self.valid_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      false
    end
  end
end
