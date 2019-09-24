class CreateOperatorActionSubNature < ActiveRecord::Migration[4.2]
  def change
    add_column :operator_actions, :sub_nature, :string
  end

  def down
    remove_column :operator_actions, :sub_nature
  end
end
