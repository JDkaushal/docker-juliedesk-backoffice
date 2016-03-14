class AddPlanningAccessColumnToOperators < ActiveRecord::Migration
  def change
    add_column :operators, :planning_access, :boolean, default: false
  end
end
