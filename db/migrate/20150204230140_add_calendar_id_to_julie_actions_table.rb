class AddCalendarIdToJulieActionsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :julie_actions, :calendar_id, :text
    remove_column :julie_actions, :event_ids
    add_column :julie_actions, :event_id, :text
  end

  def down
    remove_column :julie_actions, :calendar_id
    add_column :julie_actions, :event_ids, :text, default: "[]"
    remove_column :julie_actions, :event_id
  end
end
