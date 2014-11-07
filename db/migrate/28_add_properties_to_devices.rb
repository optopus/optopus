class AddPropertiesToDevices < ActiveRecord::Migration
  def up
    change_table :devices do |t|
      t.hstore :properties
    end
  end

  def down
    remove_column :devices, :properties
  end
end
