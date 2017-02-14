class AddClientsInRecipientsToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :clients_in_recipients, :string, array: true, default: []
  end
end
