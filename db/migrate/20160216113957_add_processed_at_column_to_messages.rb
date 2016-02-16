class AddProcessedAtColumnToMessages < ActiveRecord::Migration
  def up
    add_column :messages, :processed_at, :datetime
  end

  def down
    remove_column :messages, :processed_at
  end
end
