class AddGoogleHistoryToThreadsTable < ActiveRecord::Migration
  def up
    add_column :messages_threads, :google_history_id, :string
    add_column :messages_threads, :subject, :string
    add_column :messages_threads, :snippet, :text
  end

  def down
    remove_column :messages_threads, :google_history_id
    remove_column :messages_threads, :subject
    remove_column :messages_threads, :snippet
  end
end
