class CreateEvents < ActiveRecord::Migration
  def up
    create_table :event_types do |t|
      t.string :name
      t.timestamps
    end

    create_table :events do |t|
      t.references :event_type
      t.string :message
      t.timestamps
    end

    change_table :events do |t|
      t.hstore :properties
    end

    change_table :event_types do |t|
      t.hstore :properties
    end
  end

  def down
    drop_table :events
  end
end
