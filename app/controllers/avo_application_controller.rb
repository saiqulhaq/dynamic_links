class AvoApplicationController < Avo::ApplicationController
  include Oauth2ProxyAuthentication

  before_action :ensure_admin_user

  private

  def ensure_admin_user
    # For development, allow access with skip_auth parameter
    return if Rails.env.development? && params[:skip_auth] == 'true'

    unless user_signed_in?
      redirect_to_login
      return
    end

    unless user_admin?
      render html: '
        <div style="text-align: center; margin-top: 50px; font-family: Arial, sans-serif;">
          <h1>Access Denied</h1>
          <p>You need admin privileges to access this dashboard.</p>
          <p>Logged in as: <strong>' + current_user.email + '</strong></p>
          <p>Contact your administrator to request access.</p>
          <a href="/oauth2/sign_out" style="text-decoration: none; background: #dc3545; color: white; padding: 10px 20px; border-radius: 5px;">Sign Out</a>
        </div>
      '.html_safe, status: :forbidden
    end
  end

  # Override Avo's current_user method
  def avo_current_user
    current_user
  end

  # Make current_user available to Avo
  def current_user_method
    current_user
  end
end