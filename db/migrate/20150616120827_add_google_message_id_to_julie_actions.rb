class AddGoogleMessageIdToJulieActions < ActiveRecord::Migration
  def up
    add_column :julie_actions, :google_message_id, :string
  end

  def down
    remove_column :julie_actions, :google_message_id
  end
end
