class Avo::Actions::DynamicLinks::RegenerateApiKeyAction < Avo::BaseAction
  self.name = "Regenerate API Key"
  self.message = "Are you sure you want to regenerate the API key? This will invalidate the current key."
  self.confirm_button_label = "Regenerate"

  def handle(query:, fields:, current_user:, resource:, **args)
    query.each do |client|
      client.update!(api_key: SecureRandom.hex(32))
    end

    succeed "API key(s) regenerated successfully"
  end
end
