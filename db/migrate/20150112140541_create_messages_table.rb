class CreateMessagesTable < ActiveRecord::Migration[4.2]
  def up
    create_table :messages do |t|
      t.string :google_message_id
      t.integer :messages_thread_id
      t.datetime :received_at
      t.timestamps
    end
  end

  def down
    drop_table :messages
  end
end
