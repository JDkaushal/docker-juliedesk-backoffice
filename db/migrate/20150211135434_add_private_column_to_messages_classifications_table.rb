class AddPrivateColumnToMessagesClassificationsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :message_classifications, :private, :boolean, default: false
  end

  def down
    remove_column :message_classifications, :private
  end
end
