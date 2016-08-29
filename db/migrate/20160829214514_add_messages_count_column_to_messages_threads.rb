class AddMessagesCountColumnToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :messages_count, :integer, default: 0
  end
end
