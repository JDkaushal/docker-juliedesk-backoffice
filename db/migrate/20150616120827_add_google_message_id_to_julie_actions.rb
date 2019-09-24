class AddGoogleMessageIdToJulieActions < ActiveRecord::Migration[4.2]
  def up
    add_column :julie_actions, :google_message_id, :string
  end

  def down
    remove_column :julie_actions, :google_message_id
  end
end
