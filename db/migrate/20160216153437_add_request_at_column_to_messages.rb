class AddRequestAtColumnToMessages < ActiveRecord::Migration
  def up
    remove_column :messages, :processed_at
    add_column :messages, :request_at, :datetime
  end

  def down
    add_column :messages, :processed_at, :datetime
    remove_column :messages, :request_at
  end
end
