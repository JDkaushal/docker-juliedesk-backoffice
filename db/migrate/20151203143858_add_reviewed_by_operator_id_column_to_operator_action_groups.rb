class AddReviewedByOperatorIdColumnToOperatorActionGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :operator_actions_groups, :reviewed_by_operator_id, :integer
  end

  def down
    remove_column :operator_actions_groups, :reviewed_by_operator_id
  end
end
