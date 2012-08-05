class CreateEvents < ActiveRecord::Migration
  def up
    create_table :events do |t|
      t.string :message
      t.timestamps
    end

    change_table :events do |t|
      t.hstore :properties
    end
  end

  def down
    drop_table :events
  end
end
