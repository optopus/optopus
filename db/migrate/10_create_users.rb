require 'activerecord-postgres-hstore/activerecord'
class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :username
      t.string :display_name
    end

    change_table :users do |t|
      t.hstore :properties
    end
  end

  def down
    drop_table :users
  end
end
