class Avo::Actions::Users::ToggleAdminAction < Avo::BaseAction
  self.name = "Toggle Admin Status"
  self.message = "Are you sure you want to toggle admin status for the selected user(s)?"
  self.confirm_button_label = "Toggle Admin"

  def handle(query:, fields:, current_user:, resource:, **args)
    query.each do |user|
      old_status = user.admin?
      user.update!(admin: !user.admin?)
      
      status = user.admin? ? "granted" : "revoked"
      Rails.logger.info "Admin access #{status} for user #{user.email} by #{current_user&.email}"
    end

    count = query.count
    if count == 1
      user = query.first
      status = user.admin? ? "granted admin access" : "revoked admin access"
      succeed "Successfully #{status} for #{user.display_name}"
    else
      succeed "Successfully toggled admin status for #{count} users"
    end
  end
end