class AddActiveFlagToNodes < ActiveRecord::Migration
  def up
    change_table :nodes do |t|
      t.boolean :active, :default => true
    end
  end

  def down
    remove_column :nodes, :active
  end
end
