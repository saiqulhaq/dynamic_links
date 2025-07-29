Rails.application.routes.draw do
  mount DynamicLinks::Engine => "/"
end
