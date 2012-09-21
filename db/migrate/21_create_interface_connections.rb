class CreateInterfaceConnections < ActiveRecord::Migration
  def up
    create_table :interface_connections do |t|
      t.integer :source_interface_id
      t.integer :target_interface_id
    end
  end

  def down
    drop_table :interface_connections
  end
end
