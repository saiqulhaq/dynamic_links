class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  enum :role, { user: 0, admin: 1, platform_admin: 2 }, prefix: true

  # create platform admin user
  def self.create_platform_admin
    create!(email_address: ENV.fetch('PLATFORM_ADMIN_EMAIL'), password: ENV.fetch('PLATFORM_ADMIN_PASSWORD'),
            role: :platform_admin)
  end
end
