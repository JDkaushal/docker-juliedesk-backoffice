class CreateOperatorActionSubNature < ActiveRecord::Migration
  def change
    add_column :operator_actions, :sub_nature, :string
  end

  def down
    remove_column :operator_actions, :sub_nature
  end
end
