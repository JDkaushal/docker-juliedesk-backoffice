class AddIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :messages, :messages_thread_id
    add_index :message_interpretations, :message_id
    add_index :message_classifications, :message_id
  end
end
