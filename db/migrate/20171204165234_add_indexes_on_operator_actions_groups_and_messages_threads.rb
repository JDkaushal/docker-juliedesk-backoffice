class AddIndexesOnOperatorActionsGroupsAndMessagesThreads < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  
  def change
    add_index :messages_threads, :account_email, algorithm: :concurrently
    add_index :operator_actions_groups, :finished_at, algorithm: :concurrently
    add_index :operator_actions_groups, :initiated_at, algorithm: :concurrently
  end
end
