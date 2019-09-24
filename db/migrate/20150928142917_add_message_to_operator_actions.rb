class AddMessageToOperatorActions < ActiveRecord::Migration[4.2]
  def up
    add_column :operator_actions, :message, :text
  end

  def down
    remove_column :operator_actions, :message
  end
end
