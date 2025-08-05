class Avo::Actions::DynamicLinks::CopyShortUrlAction < Avo::BaseAction
  self.name = "Copy Short URL"
  self.message = "Copy the full short URL to clipboard"
  self.confirm_button_label = "Copy"
  self.no_confirmation = true

  def handle(query:, fields:, current_user:, resource:, **args)
    if query.count == 1
      shortened_url = query.first
      full_url = "#{shortened_url.client.scheme}://#{shortened_url.client.hostname}/#{shortened_url.short_url}"

      succeed "Short URL copied: #{full_url}"
    else
      error "Can only copy one URL at a time"
    end
  end
end
