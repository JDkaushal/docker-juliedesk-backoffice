class AddAccountRequestAutoEmailSentToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :account_request_auto_email_sent, :boolean, default: false
  end
end
