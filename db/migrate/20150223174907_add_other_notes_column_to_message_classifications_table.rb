class AddOtherNotesColumnToMessageClassificationsTable < ActiveRecord::Migration
  def up
    add_column :message_classifications, :other_notes, :text
  end

  def down
    remove_column :message_classifications, :other_notes
  end
end
