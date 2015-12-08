class AddDelegatedToSupportColumnToMessagesThreads < ActiveRecord::Migration
  def up
    add_column :messages_threads, :delegated_to_support, :boolean, default: false
  end

  def down
    remove_column :messages_threads, :delegated_to_support
  end
end
