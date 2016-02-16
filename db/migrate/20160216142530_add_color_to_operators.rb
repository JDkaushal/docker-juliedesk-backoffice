class AddColorToOperators < ActiveRecord::Migration
  def change
    add_column :operators, :color, :string, default: '#ffffff'
  end
end
