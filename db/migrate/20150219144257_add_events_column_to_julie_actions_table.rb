class AddEventsColumnToJulieActionsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :julie_actions, :events, :text, default: "[]"
  end

  def down
    remove_column :julie_actions, :events
  end
end
