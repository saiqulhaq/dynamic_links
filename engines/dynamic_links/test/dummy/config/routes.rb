# frozen_string_literal: true

Rails.application.routes.draw do
  mount DynamicLinks::Engine => '/'
end
