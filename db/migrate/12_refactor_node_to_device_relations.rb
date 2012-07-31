class RefactorNodeToDeviceRelations < ActiveRecord::Migration
  def up
    change_table :nodes do |t|
      t.hstore :properties
    end
    remove_column :nodes, :uuid
    remove_column :devices, :uuid
  end

  def down
    remove_column :nodes, :properties
  end
end
