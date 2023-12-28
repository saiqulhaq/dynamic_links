class CreateDynamicLinksClients < ActiveRecord::Migration[7.1]
  def change
    create_table :dynamic_links_clients do |t|
      t.string :name, null: false
      t.string :api_key, null: false

      t.timestamps
    end

    add_index :dynamic_links_clients, :name, unique: true
    add_index :dynamic_links_clients, :api_key, unique: true
  end
end
