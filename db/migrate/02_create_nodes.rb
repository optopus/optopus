class CreateNodes < ActiveRecord::Migration
  def up
    create_table :nodes do |t|
      t.string :hostname
      t.string :serial_number
      t.string :primary_mac_address
      t.string :uuid, :limit => 36
      t.integer :appliance_id
      t.boolean :virtual
    end
  end

  def down
    drop_table :nodes
  end
end
