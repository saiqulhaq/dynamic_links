class Avo::Resources::DynamicLinksClient < Avo::BaseResource
  self.model_class = 'DynamicLinks::Client'
  self.title = :name
  self.includes = []

  def fields
    field :id, as: :id
    field :name, as: :text, required: true, help: 'Client name for identification'
    field :api_key, as: :text, required: true, help: 'API key for authentication', hide_on: [:index]
    field :scheme, as: :select, options: %w[http https], default: 'https', required: true
    field :hostname, as: :text, required: true, help: 'Domain hostname (e.g., example.com)'
    field :created_at, as: :date_time, hide_on: %i[new edit]
    field :updated_at, as: :date_time, hide_on: %i[new edit]

    field :shortened_urls, as: :has_many
  end

  def filters
    filter Avo::Filters::DynamicLinks::SchemeFilter
  end

  def actions
    action Avo::Actions::DynamicLinks::RegenerateApiKeyAction
  end
end
