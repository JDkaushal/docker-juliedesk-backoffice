class CreateDateSuggestionsReviews < ActiveRecord::Migration[4.2]
  def change
    create_table :date_suggestions_reviews do |t|
      t.integer :julie_action_id
      t.boolean :generated_from_julie_action
      t.datetime :action_at
      t.json :date_suggestions
      t.string :review_set_status
      t.json :review_set_errors
      t.integer :review_items_incorrect_count
      t.json :review_items_errors
      t.integer :reviewed_by_operator_id
      t.string :review_status
      t.timestamps
    end
  end
end
