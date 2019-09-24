class AddClientsInRecipientsToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :clients_in_recipients, :string, array: true, default: []
  end
end
