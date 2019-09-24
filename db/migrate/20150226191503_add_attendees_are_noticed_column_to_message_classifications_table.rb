class AddAttendeesAreNoticedColumnToMessageClassificationsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :message_classifications, :attendees_are_noticed, :boolean, default: false
  end

  def down
    remove_column :message_classifications, :attendees_are_noticed
  end
end
