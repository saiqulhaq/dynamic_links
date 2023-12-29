# == Schema Information
#
# Table name: dynamic_links_clients
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  api_key    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_dynamic_links_clients_on_api_key  (api_key) UNIQUE
#  index_dynamic_links_clients_on_name     (name) UNIQUE
#
module DynamicLinks
  class Client < ApplicationRecord
    validates :name, presence: true, uniqueness: true
    validates :api_key, presence: true, uniqueness: true
  end
end
