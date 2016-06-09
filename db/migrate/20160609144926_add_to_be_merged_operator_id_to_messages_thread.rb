class AddToBeMergedOperatorIdToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :to_be_merged_operator_id, :integer
  end
end
