class CreateNodeComments < ActiveRecord::Migration
  def up
    create_table :node_comments do |t|
      t.string :comment
      t.timestamps
    end

    create_table :node_comments_nodes do |t|
      t.references :node_comment
      t.references :node
    end
  end

  def down
    drop_table :node_comments
    drop_table :node_comments_nodes
  end
end
