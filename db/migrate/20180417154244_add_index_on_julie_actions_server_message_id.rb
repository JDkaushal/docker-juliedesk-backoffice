class AddIndexOnJulieActionsServerMessageId < ActiveRecord::Migration[4.2]
  def change
    add_index :julie_actions, :server_message_id
  end
end
