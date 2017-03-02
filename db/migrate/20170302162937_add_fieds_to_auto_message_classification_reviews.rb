class AddFiedsToAutoMessageClassificationReviews < ActiveRecord::Migration
  def change
    add_column :auto_message_classification_reviews, :resolved, :boolean, default: false
    add_column :auto_message_classifications, :batch_identifier, :string
  end
end
