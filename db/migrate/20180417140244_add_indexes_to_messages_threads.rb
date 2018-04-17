class AddIndexesToMessagesThreads < ActiveRecord::Migration
  def change
    add_index :messages_threads, :in_inbox
    add_index :messages_threads, :should_follow_up
  end
end
