class CreateInterfaces < ActiveRecord::Migration
  def up
    create_table :interfaces do |t|
      t.string :name
      t.references :node
    end

    change_table :addresses do |t|
      t.references :interface
    end
  end

  def down
    drop_table :interfaces
    remove_column :addresses, :interface_id
  end
end
