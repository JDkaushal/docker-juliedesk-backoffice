class MigrateToNewEmailSystem < ActiveRecord::Migration
  def up
    add_column :messages_threads, :server_thread_id, :integer
    add_column :messages, :server_message_id, :integer
    add_column :messages_threads, :server_version, :string
    add_column :julie_actions, :server_message_id, :integer
  end

  def down
    remove_column :messages_threads, :server_thread_id
    remove_column :messages, :server_message_id
    remove_column :messages_threads, :server_version
    remove_column :julie_actions, :server_message_id
  end
end
