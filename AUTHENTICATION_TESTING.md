# Authentication System Testing Guide

This guide explains how to test the OAuth2-Proxy authentication system integrated with the Avo admin dashboard.

## Quick Development Testing

For development and testing purposes, you can bypass OAuth2-Proxy authentication:

### 1. Start Rails Server Locally

```bash
bundle exec rails server
```

### 2. Access Avo Dashboard with Development Bypass

Visit: `http://localhost:3000/avo?skip_auth=true`

This will automatically log you in as a development admin user and give you full access to the Avo dashboard.

## Full OAuth2-Proxy Testing

### 1. Set up Environment Variables

Copy `.env.example` to `.env` and fill in your Google OAuth credentials:

```bash
cp .env.example .env
# Edit .env with your Google OAuth2 credentials
```

### 2. Start with Docker Compose

```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### 3. Test Authentication Flow

1. **Visit the protected URL**: `http://localhost:4180/avo`
2. **Redirect to Google**: You'll be redirected to Google OAuth login
3. **Google Authentication**: Sign in with your Google account
4. **Admin Check**: After authentication:
   - If you're an admin user: Access granted to Avo dashboard
   - If you're not an admin: Access denied with friendly message

### 4. Test Admin Features

Once logged in as an admin, you can:

- **Manage Dynamic Links Clients**: Create, edit, delete clients
- **Manage Shortened URLs**: View, create, edit URLs
- **User Management**: View users, toggle admin status
- **Use Actions**: Copy short URLs, regenerate API keys
- **Use Filters**: Filter by client, expiration status, etc.

## Test Users

The system creates these test users automatically (via `db:seeds`):

- **admin@example.com**: Admin user (can access Avo)
- **user@example.com**: Regular user (cannot access Avo)

## Testing Different Scenarios

### 1. Admin User Access

```bash
# Simulate admin user headers (for testing)
curl -H "X-Auth-Request-Email: admin@example.com" http://localhost:3000/avo
```

### 2. Regular User Access (Should be denied)

```bash
# Simulate regular user headers
curl -H "X-Auth-Request-Email: user@example.com" http://localhost:3000/avo
```

### 3. Unauthenticated Access (Should redirect to login)

```bash
# No auth headers - should redirect to oauth2-proxy
curl http://localhost:3000/avo
```

## Manual Testing Checklist

### Authentication Flow
- [ ] Accessing `/avo` without authentication redirects to Google OAuth
- [ ] Google OAuth login works correctly
- [ ] After authentication, user is redirected back to Avo
- [ ] Admin users can access the dashboard
- [ ] Regular users are denied access with friendly message

### User Management
- [ ] New users are automatically created on first login
- [ ] User information is correctly populated from Google
- [ ] Admin status can be toggled via Avo interface
- [ ] User search and filtering works

### Dynamic Links Management
- [ ] Admin can view all clients and URLs
- [ ] Admin can create/edit/delete clients
- [ ] Admin can create/edit/delete shortened URLs
- [ ] Actions work (copy URL, regenerate API key)
- [ ] Filters work correctly

### Security
- [ ] Direct access to `/avo` without auth headers is blocked
- [ ] Regular users cannot access admin features
- [ ] OAuth2-proxy headers are properly validated
- [ ] Session handling works correctly

## Troubleshooting

### Common Issues

1. **"Access Denied" for valid admin users**
   - Check if user exists in database: `User.find_by(email: 'your-email@domain.com')`
   - Ensure user has admin flag: `user.update!(admin: true)`

2. **Headers not being passed correctly**
   - Verify oauth2-proxy configuration
   - Check nginx/reverse proxy settings
   - Enable debug logging in oauth2-proxy

3. **Development bypass not working**
   - Ensure you're using `?skip_auth=true` parameter
   - Check Rails environment is set to development
   - Verify the development user exists in database

### Debug Commands

```bash
# Check if users exist
bundle exec rails console
> User.all

# Create admin user manually
> User.create!(email: 'your-email@domain.com', name: 'Your Name', provider: 'google', uid: 'your-email@domain.com', admin: true)

# Check authentication headers in Rails logs
> Rails.logger.info request.headers.select { |k, v| k.start_with?('HTTP_X_AUTH') || k.start_with?('X-Auth') }
```

## Production Considerations

1. **Remove Development Bypass**: Ensure `skip_auth` parameter is disabled in production
2. **HTTPS Only**: Use HTTPS for all OAuth redirects and cookie security
3. **Domain Restrictions**: Configure `GOOGLE_WORKSPACE_DOMAIN` to restrict access
4. **Monitoring**: Set up logging and monitoring for authentication events
5. **Session Security**: Configure secure cookie settings and session timeouts