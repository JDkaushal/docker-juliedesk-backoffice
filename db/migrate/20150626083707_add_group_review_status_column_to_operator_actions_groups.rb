class AddGroupReviewStatusColumnToOperatorActionsGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :operator_actions_groups, :group_review_status, :string
  end

  def down
    remove_column :operator_actions_groups, :group_review_status
  end
end
