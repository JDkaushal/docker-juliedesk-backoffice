class AddCanSeeOperatorsInReviewToOperators < ActiveRecord::Migration[4.2]
  def change
    add_column :operators, :can_see_operators_in_review, :boolean, default: false
  end
end
