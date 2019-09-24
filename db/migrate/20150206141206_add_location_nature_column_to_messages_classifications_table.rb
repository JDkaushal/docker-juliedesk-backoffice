class AddLocationNatureColumnToMessagesClassificationsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :message_classifications, :location_nature, :string
  end

  def down
    remove_column :message_classifications, :location_nature
  end
end
