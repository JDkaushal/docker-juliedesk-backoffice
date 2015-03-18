class AddNumberToCallColumnToMessageClassificationsTable < ActiveRecord::Migration
  def up
    add_column :message_classifications, :number_to_call, :string
  end

  def down
    remove_column :message_classifications, :number_to_call
  end
end
