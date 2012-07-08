class CreateLocations < ActiveRecord::Migration
  def up
    create_table :locations do |t|
      t.string :common_name
      t.string :city
      t.string :state
    end
  end

  def down
    drop_table :locations
  end
end
