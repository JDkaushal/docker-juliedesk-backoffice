class AddEventUrlColumnToJulieActions < ActiveRecord::Migration[4.2]
  def up
    add_column :julie_actions, :event_url, :string
  end

  def down
    remove_column :julie_actions, :event_url
  end
end
