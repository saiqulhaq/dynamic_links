class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, limit: 1
    add_reference :users, :client, null: true, foreign_key: { to_table: :dynamic_links_clients }
  end
end
