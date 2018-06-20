class AddSaltAndEencryptionKeyIdToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :encryption_salt, :string
    add_column :messages_threads, :encryption_key_id, :string
  end
end
