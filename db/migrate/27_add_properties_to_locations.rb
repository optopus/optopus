class AddPropertiesToLocations < ActiveRecord::Migration
  def up
    change_table :locations do |t|
      t.hstore :properties
    end
  end

  def down
    remove_column :locations, :properties
  end
end
