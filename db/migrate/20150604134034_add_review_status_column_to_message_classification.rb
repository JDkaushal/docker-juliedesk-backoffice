class AddReviewStatusColumnToMessageClassification < ActiveRecord::Migration
  def up
    add_column :message_classifications, :review_status, :string
  end

  def down
    remove_column :message_classifications, :review_status
  end
end
