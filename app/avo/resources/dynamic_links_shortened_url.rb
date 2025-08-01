class Avo::Resources::DynamicLinksShortenedUrl < Avo::BaseResource
  self.model_class = "DynamicLinks::ShortenedUrl"
  self.title = :short_url
  self.includes = []

  def fields
    field :id, as: :id
    field :client, as: :belongs_to, required: true
    field :short_url, as: :text, required: true, help: "Short URL identifier"
    field :url, as: :text, required: true, help: "Original URL to redirect to"
    field :expires_at, as: :date_time, help: "Optional expiration date"
    field :created_at, as: :date_time, hide_on: [:new, :edit]
    field :updated_at, as: :date_time, hide_on: [:new, :edit]

    field :expired, as: :boolean, computed: true do
      record.expired?
    end

    field :full_short_url, as: :text, computed: true, hide_on: [:new, :edit] do
      "#{record.client.scheme}://#{record.client.hostname}/#{record.short_url}"
    end
  end

  def filters
    filter Avo::Filters::DynamicLinks::ClientFilter
    filter Avo::Filters::DynamicLinks::ExpiredFilter
  end

  def actions
    action Avo::Actions::DynamicLinks::CopyShortUrlAction
  end
end
