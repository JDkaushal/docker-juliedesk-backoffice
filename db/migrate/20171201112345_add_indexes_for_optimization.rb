class AddIndexesForOptimization < ActiveRecord::Migration
  disable_ddl_transaction!
  
  def change
    add_index :messages, :received_at, algorithm: :concurrently
    add_index :message_interpretations, :created_at, algorithm: :concurrently
    add_index :client_contacts, :email, algorithm: :concurrently
    add_index :event_title_reviews, :messages_thread_id, algorithm: :concurrently
    add_index :operator_actions, :target_id, algorithm: :concurrently
    add_index :julie_actions, :event_id, algorithm: :concurrently
  end
end
