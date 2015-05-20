class AddToFoundersMessageToMessagesThreads < ActiveRecord::Migration
  def up
    add_column :messages_threads, :to_founders_message, :text
  end

  def down
    remove_column :messages_threads, :to_founders_message
  end
end
