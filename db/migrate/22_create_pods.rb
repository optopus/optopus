class CreatePods < ActiveRecord::Migration
  def up
    create_table :pods do |t|
      t.string :name
      t.references :location
      t.timestamps
    end

    change_table :nodes do |t|
      t.references :pod
    end
  end

  def down
    drop_table :pods
    remove_column :nodes, :pod_id
  end
end
