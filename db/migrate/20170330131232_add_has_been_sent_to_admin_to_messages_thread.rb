class AddHasBeenSentToAdminToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :has_been_sent_to_admin, :boolean, default: false
  end
end
