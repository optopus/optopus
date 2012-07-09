require 'activerecord-postgres-hstore/activerecord'
class AddFactsColumnToNodes < ActiveRecord::Migration
  def up
    change_table :nodes do |t|
      t.hstore :facts
    end
  end

  def down
    remove_column :nodes, :facts
  end
end
