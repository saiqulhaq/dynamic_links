# == Route Map
#

DynamicLinks::Engine.routes.draw do
  namespace :v1 do
    post "/shortLinks", to: "short_links#create", as: :short_links
  end
end
