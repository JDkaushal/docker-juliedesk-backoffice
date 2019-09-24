class AddConstraintsDataColumnToMessageClassificationsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :message_classifications, :constraints_data, :text, default: "[]"
  end

  def down
    remove_column :message_classifications, :constraints_data
  end
end
