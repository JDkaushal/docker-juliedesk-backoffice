class AddIsMultiClientToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :is_multi_clients, :boolean, default: false
  end
end
