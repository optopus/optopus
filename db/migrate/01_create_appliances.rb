class CreateAppliances < ActiveRecord::Migration
  def up
    create_table :appliances do |t|
      t.string :serial_number
      t.string :bmc_ip_address
      t.string :bmc_mac_address
      t.string :primary_mac_address
      t.string :model
      t.string :brand
      t.string :switch_name
      t.string :switch_port
      t.string :uuid, :limit => 36, :primary => true
    end
  end

  def down
    drop_table :appliances
  end
end
