class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :ahoy_events, class_name: "Ahoy::Event"
end
