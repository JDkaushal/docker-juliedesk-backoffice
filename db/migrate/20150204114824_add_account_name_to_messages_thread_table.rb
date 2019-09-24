class AddAccountNameToMessagesThreadTable < ActiveRecord::Migration[4.2]
  def up
    add_column :messages_threads, :account_name, :string
  end

  def down
    remove_column :messages_threads, :account_name
  end
end
