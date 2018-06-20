class AddEncryptionIvToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :encryption_iv, :string
  end
end
