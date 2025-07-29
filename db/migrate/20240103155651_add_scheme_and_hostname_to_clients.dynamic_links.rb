# This migration comes from dynamic_links (originally 20240101102216)
class AddSchemeAndHostnameToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :dynamic_links_clients, :hostname, :string, null: false
    add_index :dynamic_links_clients, :hostname, unique: true

    add_column :dynamic_links_clients, :scheme, :string, default: 'https', null: false
  end
end
