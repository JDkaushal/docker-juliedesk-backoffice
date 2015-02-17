class AddDelegatedToFoundersColumnToMessagesThreadTable < ActiveRecord::Migration
  def up
    add_column :messages_threads, :delegated_to_founders, :boolean, default: false
  end

  def down
    remove_column :messages_threads, :delegated_to_founders
  end
end
