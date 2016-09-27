class AddFinishedAtColumnToOperatorActionsGroups < ActiveRecord::Migration
  def change
    add_column :operator_actions_groups, :finished_at, :datetime
  end
end
