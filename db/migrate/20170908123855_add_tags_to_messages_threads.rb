class AddTagsToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :tags, :string, array: true
    change_column_default :messages_threads, :tags, []
  end
end
