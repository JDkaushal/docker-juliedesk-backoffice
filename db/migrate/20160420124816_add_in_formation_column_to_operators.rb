class AddInFormationColumnToOperators < ActiveRecord::Migration[4.2]
  def change
    add_column :operators, :in_formation, :boolean, default: false
  end
end
