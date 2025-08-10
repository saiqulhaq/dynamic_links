# Security Improvements

## URL Validation Security Fix

### Issue

The previous URL validator had a security vulnerability where it used substring matching to check for malicious domains. This could be bypassed by embedding the blocked string in different URL components.

**Vulnerable code:**

```ruby
return true if host.include?('evil.com')
```

**Bypass examples:**

- `http://legitimate.com/evil.com` (in path)
- `http://legitimate.com?x=evil.com` (in query)
- `http://evil.com.attacker.net` (subdomain confusion)

### Fix

1. **Removed vulnerable substring check**: Eliminated the `host.include?('evil.com')` check that could be bypassed.

2. **Added allowlist configuration**: Implemented a proper allowlist system for redirect hosts:

   ```ruby
   DynamicLinks.configure do |config|
     config.allowed_redirect_hosts = ['example.com', 'trusted.org']
   end
   ```

3. **Proper host validation**: The validator now:
   - Parses URLs properly before checking hosts
   - Supports exact domain matches and proper subdomain validation
   - Prevents subdomain confusion attacks
   - Uses case-insensitive matching
   - Maintains backward compatibility (empty allowlist allows all)

### Usage

#### Allow specific domains only:

```ruby
DynamicLinks.configure do |config|
  config.allowed_redirect_hosts = [
    'example.com',
    'www.example.com',
    'api.example.com'
  ]
end
```

#### Allow all domains (default behavior):

```ruby
DynamicLinks.configure do |config|
  config.allowed_redirect_hosts = [] # Empty array = no restrictions
end
```

### Security Benefits

- ✅ Prevents malicious domain bypass attacks
- ✅ Proper subdomain validation
- ✅ Case-insensitive matching
- ✅ Prevents subdomain confusion attacks
- ✅ Maintains backward compatibility
- ✅ Comprehensive test coverage

This follows security best practices by using explicit allowlists instead of vulnerable substring matching.
