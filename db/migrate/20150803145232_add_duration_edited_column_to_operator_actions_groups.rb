class AddDurationEditedColumnToOperatorActionsGroups < ActiveRecord::Migration
  def up
    add_column :operator_actions_groups, :duration_edited, :boolean, default: false
  end

  def down
    remove_column :operator_actions_groups, :duration_edited
  end
end
