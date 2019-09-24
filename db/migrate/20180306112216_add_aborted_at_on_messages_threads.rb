class AddAbortedAtOnMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :aborted_at, :datetime
  end
end
