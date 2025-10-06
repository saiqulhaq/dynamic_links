# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :require_authentication

  def home; end
end
