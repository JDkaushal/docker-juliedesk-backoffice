class AddLockedByOperatorIdColumnToMessageThreads < ActiveRecord::Migration
  def up
    add_column :messages_threads, :locked_by_operator_id, :integer
  end

  def down
    remove_column :messages_threads, :locked_by_operator_id
  end
end
