class AddAbortedAtOnMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :aborted_at, :datetime
  end
end
