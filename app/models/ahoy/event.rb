class Ahoy::Event < ApplicationRecord
  include Ahoy::QueryMethods
  
  self.table_name = "ahoy_events"

  belongs_to :visit, class_name: "Ahoy::Visit", foreign_key: "ahoy_visits_id"
end
