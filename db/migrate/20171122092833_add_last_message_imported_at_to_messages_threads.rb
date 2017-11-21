class AddLastMessageImportedAtToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :last_message_imported_at, :datetime
  end
end
