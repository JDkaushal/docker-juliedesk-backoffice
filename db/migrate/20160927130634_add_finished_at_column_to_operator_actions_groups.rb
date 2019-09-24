class AddFinishedAtColumnToOperatorActionsGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :operator_actions_groups, :finished_at, :datetime
  end
end
