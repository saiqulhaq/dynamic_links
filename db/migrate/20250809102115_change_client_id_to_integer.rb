class ChangeClientIdToInteger < ActiveRecord::Migration[8.0]
  def change
    change_column :dynamic_links_analytics_link_clicks, :client_id, :integer, null: false, using: 'client_id::integer'
  end
end
