class AddWasMergedColumnToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :was_merged, :boolean, default: false
  end
end
