class AddToBeMergedToThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :to_be_merged, :boolean, default: false
  end
end
