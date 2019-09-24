class LockUpdatedAtColumnToMessagesThreads < ActiveRecord::Migration[4.2]
  def up
    add_column :messages_threads, :locked_at, :datetime
  end

  def down
    remove_column :messages_threads, :locked_at
  end
end
