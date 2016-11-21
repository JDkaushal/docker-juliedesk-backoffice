class RenameDelegatedToSupportToSentToAdminOnMessagesThread < ActiveRecord::Migration
  def change
    rename_column :messages_threads, :delegated_to_founders, :sent_to_admin
    rename_column :messages_threads, :to_founders_message, :to_admin_message
  end
end
