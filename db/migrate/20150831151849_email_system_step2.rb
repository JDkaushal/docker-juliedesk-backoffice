class EmailSystemStep2 < ActiveRecord::Migration[4.2]
  def up
    remove_column :messages_threads, :google_thread_id
    remove_column :messages, :google_message_id
    remove_column :messages_threads, :google_history_id
    remove_column :julie_actions, :google_message_id
  end

  def down
    add_column :messages_threads, :google_thread_id, :string
    add_column :messages, :google_message_id, :string
    add_column :messages_threads, :google_history_id, :string
    add_column :julie_actions, :google_message_id, :integer
  end
end