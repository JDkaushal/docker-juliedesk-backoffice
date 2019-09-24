class AddSaltAndEencryptionKeyIdToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :encryption_salt, :string
    add_column :messages_threads, :encryption_key_id, :string
  end
end
