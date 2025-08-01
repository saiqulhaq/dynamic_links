class Avo::Resources::User < Avo::BaseResource
  self.title = :display_name
  self.includes = []
  self.search = {
    query: -> { query.ransack(email_cont: q, name_cont: q, m: "or").result(distinct: false) }
  }
  
  def fields
    field :id, as: :id
    field :email, as: :text, required: true, help: "User's email address from Google OAuth"
    field :name, as: :text, required: true, help: "Display name from Google profile"
    field :provider, as: :select, options: ["google"], default: "google", help: "OAuth provider", hide_on: [:index]
    field :uid, as: :text, help: "Unique identifier from OAuth provider", hide_on: [:index]
    field :admin, as: :boolean, help: "Grant admin access to Avo dashboard"
    field :created_at, as: :date_time, hide_on: [:new, :edit]
    field :updated_at, as: :date_time, hide_on: [:new, :edit]

    field :display_name, as: :text, computed: true, hide_on: [:new, :edit] do
      record.display_name
    end
  end

  def filters
    filter Avo::Filters::Users::AdminFilter
  end

  def actions
    action Avo::Actions::Users::ToggleAdminAction
  end
end
