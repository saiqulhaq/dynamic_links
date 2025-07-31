class CreateDynamicLinksClients < ActiveRecord::Migration[7.1]
  def change
    create_table :dynamic_links_clients do |t|
      t.string :name, null: false
      t.string :api_key, null: false
      t.string :scheme, default: 'https', null: false
      t.string :hostname, null: false

      t.timestamps
    end

    create_reference_table(:dynamic_links_clients) if DynamicLinks.configuration.db_infra_strategy == :sharding

    add_index :dynamic_links_clients, :name
    add_index :dynamic_links_clients, :api_key, unique: true
    add_index :dynamic_links_clients, :hostname, unique: true
  end
end
