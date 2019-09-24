class AddEncryptionIvToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :encryption_iv, :string
  end
end
