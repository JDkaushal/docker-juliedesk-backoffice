class AddCanSeeOperatorsInReviewToOperators < ActiveRecord::Migration
  def change
    add_column :operators, :can_see_operators_in_review, :boolean, default: false
  end
end
