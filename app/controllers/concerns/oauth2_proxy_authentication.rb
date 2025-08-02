module Oauth2ProxyAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user_from_proxy_headers
    helper_method :current_user, :user_signed_in?, :user_admin?
  end

  private

  def authenticate_user_from_proxy_headers
    # In development, allow bypassing authentication
    if Rails.env.development? && params[:skip_auth] == 'true'
      @current_user = User.find_or_create_by!(
        email: 'dev@example.com',
        name: 'Development User',
        provider: 'google',
        uid: 'dev@example.com',
        admin: true
      )
      return
    end

    # Check for oauth2-proxy headers
    email = request.headers['X-Auth-Request-Email']
    
    if email.present?
      @current_user = User.from_oauth2_proxy_headers(request.headers)
    else
      # If no auth headers, redirect to oauth2-proxy login
      redirect_to_login unless devise_controller_or_public_path?
    end
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user.present?
  end

  def user_admin?
    current_user&.admin?
  end

  def require_admin!
    unless user_admin?
      if user_signed_in?
        render json: { error: 'Access denied. Admin privileges required.' }, status: :forbidden
      else
        redirect_to_login
      end
    end
  end

  def redirect_to_login
    # In production, this would redirect to oauth2-proxy login
    # In development with Docker, it would be http://localhost:4180/oauth2/start
    login_url = Rails.env.production? ? '/oauth2/start' : 'http://localhost:4180/oauth2/start'
    redirect_to login_url
  end

  def devise_controller_or_public_path?
    # Allow access to health check and other public endpoints
    public_paths = ['/up', '/health', '/ping']
    public_paths.any? { |path| request.path.start_with?(path) }
  end
end