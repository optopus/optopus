class AddLocationIdToAppliances < ActiveRecord::Migration
  def up
    change_table :appliances do |t|
      t.integer :location_id
    end
  end

  def down
    remove_column :location_id
  end
end
