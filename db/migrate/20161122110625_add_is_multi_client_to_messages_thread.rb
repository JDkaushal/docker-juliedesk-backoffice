class AddIsMultiClientToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :is_multi_clients, :boolean, default: false
  end
end
