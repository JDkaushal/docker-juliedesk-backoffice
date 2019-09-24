class AddColorToOperators < ActiveRecord::Migration[4.2]
  def change
    add_column :operators, :color, :string, default: '#ffffff'
  end
end
