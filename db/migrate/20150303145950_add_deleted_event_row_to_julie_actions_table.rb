class AddDeletedEventRowToJulieActionsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :julie_actions, :deleted_event, :boolean, default: false
  end

  def down
    remove_column :julie_actions, :deleted_event
  end
end
