class CreateOperatorActionsGroups < ActiveRecord::Migration
  def up
    create_table :operator_actions_groups do |t|
      t.column :operator_id, :integer
      t.column :messages_thread_id, :integer
      t.column :label, :string
      t.column :target_id, :integer
      t.column :target_type, :string
      t.column :review_status, :string
      t.column :review_notation, :integer
      t.column :review_comment, :text
      t.column :initiated_at, :datetime
      t.column :duration, :integer
      t.timestamps
    end

    add_column :operator_actions, :operator_actions_group_id, :integer
  end

  def down
    drop_table :operator_actions_groups
    remove_column :operator_actions, :operator_actions_group_id
  end
end
