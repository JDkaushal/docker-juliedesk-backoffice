class AddProcessedInColumns < ActiveRecord::Migration
  def up
    add_column :message_classifications, :processed_in, :integer
    add_column :julie_actions, :processed_in, :integer
  end

  def down
    remove_column :message_classifications, :processed_in
    remove_column :julie_actions, :processed_in
  end
end
