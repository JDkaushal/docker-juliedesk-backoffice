class AddIndexOnJulieActionsOperatorActions < ActiveRecord::Migration
  def change
    add_index :julie_actions, :created_at
    add_index :operator_actions, :messages_thread_id
  end
end
