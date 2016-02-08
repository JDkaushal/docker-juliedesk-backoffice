class AddEnabledColumnToOperatorsTable < ActiveRecord::Migration
  def up
    add_column :operators, :enabled, :boolean, default: true
  end

  def down
    remove_column :operators, :enabled
  end
end
