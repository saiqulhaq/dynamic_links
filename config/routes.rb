# == Route Map
#

DynamicLinks::Engine.routes.draw do
  get '/:short_url', to: 'redirects#show', as: :shortened
  namespace :v1 do
    post "/shortLinks", to: "short_links#create", as: :short_links
    get "/shortLinks/:short_url", to: "short_links#expand", as: :full_url
  end
end
