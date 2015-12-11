class AddIsReviewColumnToOperatorPresences < ActiveRecord::Migration
  def up
    add_column :operator_presences, :is_review, :boolean, default: false
  end

  def down
    remove_column :operator_presences, :is_review
  end
end
