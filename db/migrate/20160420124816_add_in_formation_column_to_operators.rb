class AddInFormationColumnToOperators < ActiveRecord::Migration
  def change
    add_column :operators, :in_formation, :boolean, default: false
  end
end
