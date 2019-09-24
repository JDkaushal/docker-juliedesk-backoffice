class AddWasMergedColumnToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :was_merged, :boolean, default: false
  end
end
