class AddPropertiesToNetworks < ActiveRecord::Migration
  def up
    change_table :networks do |t|
      t.hstore :properties
    end
    change_table :addresses do |t|
      t.hstore :properties
    end
  end

  def down
    remove_column :networks, :properties
    remove_column :addresses, :properties
  end
end
