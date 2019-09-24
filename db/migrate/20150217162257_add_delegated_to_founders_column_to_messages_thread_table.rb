class AddDelegatedToFoundersColumnToMessagesThreadTable < ActiveRecord::Migration[4.2]
  def up
    add_column :messages_threads, :delegated_to_founders, :boolean, default: false
  end

  def down
    remove_column :messages_threads, :delegated_to_founders
  end
end
