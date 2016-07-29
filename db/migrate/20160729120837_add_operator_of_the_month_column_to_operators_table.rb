class AddOperatorOfTheMonthColumnToOperatorsTable < ActiveRecord::Migration
  def change
    add_column :operators, :operator_of_the_month, :boolean, default: false
  end
end
