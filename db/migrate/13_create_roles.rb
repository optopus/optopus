require 'activerecord-postgres-hstore/activerecord'
class CreateRoles < ActiveRecord::Migration
  def up
    create_table :roles do |t|
      t.string :name
      t.timestamps
    end

    change_table :roles do |t|
      t.hstore :properties
    end
  end

  def down
    drop_table :roles
  end
end
