class CreateMessagesThreadsTable < ActiveRecord::Migration[4.2]
  def up
    create_table :messages_threads do |t|
      t.string :google_thread_id
      t.string :account_email
      t.boolean :in_inbox, default: false
      t.string :locale
      t.timestamps
    end
  end

  def down
    drop_table :messages_threads
  end
end
