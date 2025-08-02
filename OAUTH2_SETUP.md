# OAuth2-Proxy with Google Cloud Identity Setup

This guide walks you through setting up OAuth2-Proxy with Google Cloud Identity (Google Workspace) for authenticating users to access the Avo admin dashboard.

## Prerequisites

- Google Cloud Console access
- Google Workspace admin privileges (for domain restrictions)
- Docker and Docker Compose installed

## Step 1: Set up Google OAuth2 Application

### 1.1 Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API (or Google Identity API)

### 1.2 Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **Internal** if you want to restrict to your Google Workspace domain
3. Fill in the required information:
   - App name: `Dynamic Links Admin`
   - User support email: Your email
   - Developer contact information: Your email
4. Add scopes: `email`, `profile`, `openid`
5. Save and continue

### 1.3 Create OAuth2 Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client IDs**
3. Choose **Web application**
4. Set the name: `Dynamic Links OAuth2-Proxy`
5. Add authorized redirect URIs:
   - `http://localhost:4180/oauth2/callback` (for development)
   - `https://yourdomain.com/oauth2/callback` (for production)
6. Click **Create**
7. Save the **Client ID** and **Client Secret**

## Step 2: Configure Environment Variables

### 2.1 Generate Cookie Secret

```bash
openssl rand -base64 32
```

### 2.2 Update .env file

Copy `.env.example` to `.env` and update the following variables:

```bash
# Copy the example file
cp .env.example .env

# Edit the file with your values
export GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
export GOOGLE_CLIENT_SECRET=your-client-secret
export OAUTH2_PROXY_COOKIE_SECRET=your-generated-cookie-secret

# Optional: Restrict to your Google Workspace domain
export GOOGLE_WORKSPACE_DOMAIN=your-company.com
```

## Step 3: Start the Services

### 3.1 Start with Docker Compose

```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### 3.2 Access the Application

1. Open your browser and go to `http://localhost:4180`
2. You'll be redirected to Google for authentication
3. After successful authentication, you'll be redirected to the Avo admin dashboard at `http://localhost:4180/avo`

## Step 4: Production Configuration

### 4.1 Domain Configuration

For production, update the following:

1. **OAuth2-Proxy configuration**:
   ```yaml
   OAUTH2_PROXY_REDIRECT_URL: https://yourdomain.com/oauth2/callback
   ```

2. **Google Cloud Console**:
   - Add your production domain to authorized redirect URIs
   - Update authorized JavaScript origins

### 4.2 Security Considerations

1. **HTTPS**: Always use HTTPS in production
2. **Cookie Security**: Set secure cookie flags
3. **Domain Restrictions**: Use `GOOGLE_WORKSPACE_DOMAIN` to restrict access
4. **Network Security**: Ensure oauth2-proxy is behind a reverse proxy (nginx/caddy)

## Step 5: Advanced Configuration

### 5.1 Group-based Access Control

To restrict access to specific Google Groups:

1. Create a service account in Google Cloud Console
2. Enable Domain-wide Delegation
3. Add the service account to Google Workspace Admin
4. Configure oauth2-proxy with group restrictions:

```yaml
OAUTH2_PROXY_GOOGLE_GROUP: admin-group@your-company.com
OAUTH2_PROXY_GOOGLE_ADMIN_EMAIL: admin@your-company.com
OAUTH2_PROXY_GOOGLE_SERVICE_ACCOUNT_JSON: /path/to/service-account.json
```

### 5.2 Custom Headers

OAuth2-Proxy passes the following headers to your Rails app:

- `X-Auth-Request-User`: User's email
- `X-Auth-Request-Email`: User's email
- `X-Auth-Request-Preferred-Username`: Username
- `Authorization`: Bearer token (if `PASS_ACCESS_TOKEN=true`)

## Troubleshooting

### Common Issues

1. **"Invalid redirect URI"**: Ensure the redirect URI in Google Cloud Console matches exactly
2. **"Access denied"**: Check if the user's email domain is allowed
3. **"Cookie secret error"**: Ensure the cookie secret is properly base64 encoded
4. **"Upstream connection failed"**: Verify the Rails app is running and accessible

### Debug Mode

Enable debug logging in oauth2-proxy:

```yaml
OAUTH2_PROXY_LOG_LEVEL: debug
```

### Health Checks

- OAuth2-Proxy health: `http://localhost:4180/ping`
- Rails app health: `http://localhost:3000/up`

## Security Notes

1. Never commit real credentials to version control
2. Use strong, unique cookie secrets
3. Regularly rotate OAuth2 credentials
4. Monitor access logs
5. Use HTTPS in production
6. Consider implementing session timeouts