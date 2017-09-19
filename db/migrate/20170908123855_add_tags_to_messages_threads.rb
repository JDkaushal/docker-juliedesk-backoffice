class AddTagsToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :tags, :string, array: true
    change_column_default :messages_threads, :tags, []
  end
end
