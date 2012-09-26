class CreateNodeGroups < ActiveRecord::Migration
  def up
    create_table :node_groups do |t|
      t.string :name
      t.timestamps
    end

    create_table :node_groups_nodes do |t|
      t.references :node_group
      t.references :node
    end
  end

  def down
    drop_table :node_groups
    drop_table :node_groups_nodes
  end
end
