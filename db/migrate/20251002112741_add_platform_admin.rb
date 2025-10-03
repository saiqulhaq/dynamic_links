class AddPlatformAdmin < ActiveRecord::Migration[8.0]
  def up
    User.create_platform_admin
  end
end
