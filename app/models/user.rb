class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  scope :admins, -> { where(admin: true) }

  # Find or create user from oauth2-proxy headers
  def self.from_oauth2_proxy_headers(headers)
    email = headers['HTTP_X_AUTH_REQUEST_EMAIL'] || headers['X-Auth-Request-Email']
    name = headers['HTTP_X_AUTH_REQUEST_PREFERRED_USERNAME'] || 
           headers['X-Auth-Request-Preferred-Username'] ||
           email&.split('@')&.first
    
    return nil unless email

    # Use email as UID for Google OAuth
    uid = email
    provider = 'google'

    user = find_or_initialize_by(email: email)
    
    if user.new_record?
      user.name = name || email.split('@').first
      user.provider = provider
      user.uid = uid
      user.admin = false # Default to non-admin, can be changed manually
      user.save!
    else
      # Update name if it has changed
      user.update!(name: name) if name && user.name != name
    end

    user
  end

  def display_name
    name.presence || email.split('@').first
  end

  def admin?
    admin
  end

  def google_user?
    provider == 'google'
  end
end
