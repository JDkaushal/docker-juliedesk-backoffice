class AddActiveColumnToOperators < ActiveRecord::Migration[4.2]
  def up
    add_column :operators, :active, :boolean, default: false
  end

  def down
    remove_column :operators, :active
  end
end
