class AddProvisionedToAppliances < ActiveRecord::Migration
  def up
    change_table :appliances do |t|
      t.boolean :provisioned
    end
  end

  def down
    remove_column :provisioned
  end
end
