class AddMessagesCountColumnToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :messages_count, :integer, default: 0
  end
end
