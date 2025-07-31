# frozen_string_literal: true

module DynamicLinks
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
