class CreateNetworksAndAddresses < ActiveRecord::Migration
  def up
    create_table :networks do |t|
      t.cidr :address
      t.string :description
      t.references :location
    end

    create_table :addresses do |t|
      t.inet :ip_address
      t.string :description
      t.references :network
      t.references :node
    end

    add_index :networks, :address, :unique => true
    add_index :addresses, :ip_address, :unique => true
  end

  def down
    drop_table :networks
    drop_table :addresses
  end
end
