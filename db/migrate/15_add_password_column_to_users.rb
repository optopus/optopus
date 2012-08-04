class AddPasswordColumnToUsers < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.string :password
    end
  end

  def down
    remove_column :users, :password
  end
end
