class AddArchivedColumnToMessagesTable < ActiveRecord::Migration
  def up
    add_column :messages, :archived, :boolean, default: false
  end

  def down
    remove_column :messages, :archived
  end
end
