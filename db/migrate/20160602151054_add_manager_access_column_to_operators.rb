class AddManagerAccessColumnToOperators < ActiveRecord::Migration
  def change
    add_column :operators, :manager_access, :boolean, default: false
  end
end
