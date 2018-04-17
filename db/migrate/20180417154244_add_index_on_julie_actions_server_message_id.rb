class AddIndexOnJulieActionsServerMessageId < ActiveRecord::Migration
  def change
    add_index :julie_actions, :server_message_id
  end
end
