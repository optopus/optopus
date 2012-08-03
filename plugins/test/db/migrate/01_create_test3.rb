class CreateTest3 < ActiveRecord::Migration
  def up
    create_table :test3 do |t|
      t.string :what
    end
  end

  def down
    drop_table :test3
  end
end
