class AddOtherNotesColumnToMessageClassificationsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :message_classifications, :other_notes, :text
  end

  def down
    remove_column :message_classifications, :other_notes
  end
end
