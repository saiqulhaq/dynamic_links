# == Route Map
#

DynamicLinks::Engine.routes.draw do
  get '/:short_url', to: 'redirects#show', as: :shortened
  namespace :v1 do
    post "/shortLinks", to: "short_links#create", as: :short_links
    post "/shortLinks/findOrCreate", to: "short_links#find_or_create", as: :find_or_create_short_link
    get "/shortLinks/:short_url", to: "short_links#expand", as: :expand_short_link
  end
end
