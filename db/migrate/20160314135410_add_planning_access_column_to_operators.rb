class AddPlanningAccessColumnToOperators < ActiveRecord::Migration[4.2]
  def change
    add_column :operators, :planning_access, :boolean, default: false
  end
end
