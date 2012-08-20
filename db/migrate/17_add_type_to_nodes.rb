class AddTypeToNodes < ActiveRecord::Migration
  def up
    change_table :nodes do |t|
      t.string :type
    end
  end

  def down
    remove_column :nodes, :type
  end
end
