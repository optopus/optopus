class CreateTest < ActiveRecord::Migration
  def up
    create_table :test do |t|
      t.string :what
    end
  end

  def down
    drop_table :test
  end
end
