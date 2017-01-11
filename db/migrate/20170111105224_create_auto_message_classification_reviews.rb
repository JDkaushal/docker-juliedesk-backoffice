class CreateAutoMessageClassificationReviews < ActiveRecord::Migration
  def change
    create_table :auto_message_classification_reviews do |t|
      t.integer :auto_message_classification_id
      t.integer :operator_id
      t.integer :notation
      t.text    :comments
      t.text    :tags
      t.timestamps
    end

    remove_column :auto_message_classifications, :notation
    remove_column :auto_message_classifications, :notation_comments
    remove_column :auto_message_classifications, :notation_tags
  end
end
