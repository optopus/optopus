class CreateTest2 < ActiveRecord::Migration
  def up
    create_table :test2 do |t|
      t.string :what
    end
  end

  def down
    drop_table :test2
  end
end
