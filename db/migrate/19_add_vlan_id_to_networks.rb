class AddVlanIdToNetworks < ActiveRecord::Migration
  def up
    change_table :networks do |t|
      t.integer :vlan_id
    end
  end

  def down
    remove_column :networks, :vlan_id
  end
end
