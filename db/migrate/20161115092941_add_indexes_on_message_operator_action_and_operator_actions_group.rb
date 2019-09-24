class AddIndexesOnMessageOperatorActionAndOperatorActionsGroup < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :messages, :server_message_id, algorithm: :concurrently
    add_index :operator_actions, :operator_actions_group_id, algorithm: :concurrently
    add_index :operator_actions_groups, :operator_id, algorithm: :concurrently
  end
end
