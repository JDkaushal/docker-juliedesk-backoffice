class AddEventsColumnToJulieActionsTable < ActiveRecord::Migration
  def up
    add_column :julie_actions, :events, :text, default: "[]"
  end

  def down
    remove_column :julie_actions, :events
  end
end
