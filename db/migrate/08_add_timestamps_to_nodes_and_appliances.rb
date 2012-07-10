class AddTimestampsToNodesAndAppliances < ActiveRecord::Migration
  def up
    change_table :nodes do |t|
      t.timestamps
    end

    change_table :appliances do |t|
      t.timestamps
    end
  end

  def down
    remove_column :nodes, :updated_at, :created_at
    remove_column :appliances, :updated_at, :created_at
  end
end
