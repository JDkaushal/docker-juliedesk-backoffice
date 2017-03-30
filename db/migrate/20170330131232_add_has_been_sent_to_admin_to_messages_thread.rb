class AddHasBeenSentToAdminToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :has_been_sent_to_admin, :boolean, default: false
  end
end
