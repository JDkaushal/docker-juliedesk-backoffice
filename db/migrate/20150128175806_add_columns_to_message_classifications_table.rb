class AddColumnsToMessageClassificationsTable < ActiveRecord::Migration

  def up
    add_column :message_classifications, :locale, :string
    add_column :message_classifications, :timezone, :string
  end

  def down
    remove_column :message_classifications, :locale
    remove_column :message_classifications, :timezone
  end
end
