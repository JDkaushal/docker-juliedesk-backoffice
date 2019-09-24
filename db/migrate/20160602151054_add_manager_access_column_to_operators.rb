class AddManagerAccessColumnToOperators < ActiveRecord::Migration[4.2]
  def change
    add_column :operators, :manager_access, :boolean, default: false
  end
end
