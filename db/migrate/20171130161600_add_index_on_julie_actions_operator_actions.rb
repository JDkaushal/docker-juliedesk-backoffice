class AddIndexOnJulieActionsOperatorActions < ActiveRecord::Migration[4.2]
  def change
    add_index :julie_actions, :created_at
    add_index :operator_actions, :messages_thread_id
  end
end
