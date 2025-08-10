# frozen_string_literal: true

require 'cgi'

module DynamicLinks
  class Validator
    DANGEROUS_PROTOCOLS = %w[javascript data file ftp ldap gopher dict tftp telnet ssh smtp pop3 imap vbscript].freeze
    INTERNAL_NETWORKS = [
      /\A127\./,
      /\Alocalhost\z/,
      /\A192\.168\./,
      /\A10\./,
      /\A172\.(1[6-9]|2[0-9]|3[01])\./,
      /\A169\.254\./,
      /\A::1\z/,
      /\A0\.0\.0\.0/,
      /\A\[::1\]/
    ].freeze

    METADATA_HOSTS = %w[
      169.254.169.254
      metadata.google.internal
    ].freeze

    SUSPICIOUS_PORTS = [22, 23, 25, 110, 143, 993, 995, 3389, 5432, 3306].freeze

    # Validates if the given URL is a valid and safe HTTP or HTTPS URL
    # @param url [String] The URL to validate
    # @return [Boolean] true if valid, false otherwise
    def self.valid_url?(url)
      return false if url.blank?

      # Check for header injection attempts
      return false if url.include?("\r") || url.include?("\n")

      # Check for encoded header injection
      return false if url.match?(/%0[ad]/i) # \r and \n encoded

      # Decode URL to check actual content
      decoded_url = CGI.unescape(url)
      return false if decoded_url.include?("\r") || decoded_url.include?("\n")

      uri = URI.parse(decoded_url)

      # Only allow HTTP and HTTPS protocols
      return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      return false if uri.scheme.blank? || uri.host.blank?

      # Block dangerous protocols
      return false if DANGEROUS_PROTOCOLS.include?(uri.scheme&.downcase)

      # Block URLs with embedded credentials
      return false if uri.userinfo.present?

      # Check against allowed hosts if configured
      return false unless allowed_host?(uri.host)

      # Check for subdomain confusion attacks
      return false if subdomain_confusion?(uri.host)

      # Block internal network addresses
      return false if internal_network?(uri.host)

      # Block cloud metadata endpoints
      return false if METADATA_HOSTS.include?(uri.host&.downcase)

      # Block suspicious ports
      return false if uri.port && SUSPICIOUS_PORTS.include?(uri.port)

      # Block DNS rebinding attempts
      return false if dns_rebinding_attempt?(uri.host)

      # Block URLs that are too long
      return false if url.length > 2083

      # Check for path traversal patterns in URL
      return false if contains_path_traversal?(decoded_url)

      true
    rescue URI::InvalidURIError, Addressable::URI::InvalidURIError
      false
    end

    def self.allowed_host?(host)
      return true if host.blank? # Let other validations handle blank hosts

      # Get the allowed hosts from configuration (static allowlist)
      allowed_hosts = DynamicLinks.configuration.allowed_redirect_hosts

      # If configuration allowlist is empty, allow all hosts (backward compatibility)
      # This maintains the original behavior where any valid HTTP/HTTPS URL could be shortened
      return true if allowed_hosts.empty?

      # Check static configuration first
      return true if static_allowlist_allows?(host, allowed_hosts)

      # Fallback to dynamic client hostnames if static config doesn't match
      dynamic_client_host_allowed?(host)
    end

    def self.static_allowlist_allows?(host, allowed_hosts)
      # Normalize host for comparison
      normalized_host = host.downcase.strip

      # Check for exact match or subdomain match
      allowed_hosts.any? do |allowed_host|
        # Exact match
        normalized_host == allowed_host ||
          # Subdomain match - ensure it's a proper subdomain, not just a substring
          (normalized_host.end_with?(".#{allowed_host}") &&
           !normalized_host.include?('..') && # Prevent path traversal in hostname
           normalized_host.split('.').all? { |part| part.present? }) # Ensure no empty parts
      end
    end

    def self.dynamic_client_host_allowed?(host)
      return true if host.blank?

      # Normalize host for comparison
      normalized_host = host.downcase.strip

      # Check if this host matches any registered DynamicLinks::Client hostname
      # This allows immediate use of new clients without restart
      DynamicLinks::Client.exists?(hostname: normalized_host)
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished => e
      # If database is not available, fall back to allowing the host
      # This prevents issues during database setup/migrations
      Rails.logger&.debug("DynamicLinks URL validation database check failed, allowing host: #{e.message}")
      true
    end

    def self.internal_network?(host)
      return false if host.blank?

      # Normalize host for IP checking
      host = host.downcase.strip

      INTERNAL_NETWORKS.any? { |pattern| pattern.match?(host) }
    end

    def self.dns_rebinding_attempt?(host)
      return false if host.blank?

      # Check for encoded IP addresses or suspicious patterns
      host = host.downcase

      # Check for hex encoded IPs like 7f000001.example.com (127.0.0.1)
      return true if host.match?(/\A[0-9a-f]{8}\./)

      # Check for dashed IP notation like 127-0-0-1.example.com
      return true if host.match?(/\A\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3}\./)

      # Check for localhost subdomains
      return true if host.match?(/\A(127\.0\.0\.1|localhost)\./)

      false
    end

    def self.subdomain_confusion?(host)
      return false if host.blank?

      host = host.downcase

      # Check for patterns like example.com.evil.com or example.com@evil.com
      # This helps prevent subdomain confusion attacks
      return true if host.include?('@')
      return true if host.match?(/\.com\..+\.com/)
      return true if host.match?(/\.org\..+\.org/)

      # Check for path traversal-like patterns in hostnames
      return true if host.include?('/..')
      return true if host.include?('/../')

      # Remove the vulnerable 'evil.com' string check
      # The previous check was: return true if host.include?('evil.com')
      # This was vulnerable to bypass attacks as it could match:
      # - http://example.com/evil.com (path component)
      # - http://example.com?x=evil.com (query parameter)
      # - http://example.com#evil.com (fragment)
      # Instead, rely on proper host validation through allowlists
      # in the calling code rather than blocklist substring matching

      false
    end

    def self.contains_path_traversal?(url)
      return false if url.blank?

      # Check for path traversal patterns in the entire URL
      return true if url.include?('/..')
      return true if url.include?('/../')
      return true if url.include?('../')

      false
    end
  end
end
