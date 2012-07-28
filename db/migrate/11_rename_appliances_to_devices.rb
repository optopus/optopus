class RenameAppliancesToDevices < ActiveRecord::Migration
  def up
    rename_table :appliances, :devices
    rename_column :nodes, :appliance_id, :device_id
  end

  def down
    rename_table :devices, :appliances
    rename_column :nodes, :device_id, :appliance_id
  end
end
