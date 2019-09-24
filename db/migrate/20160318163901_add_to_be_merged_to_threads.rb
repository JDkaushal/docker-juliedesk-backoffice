class AddToBeMergedToThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :to_be_merged, :boolean, default: false
  end
end
