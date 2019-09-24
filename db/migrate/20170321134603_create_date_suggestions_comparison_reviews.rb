class CreateDateSuggestionsComparisonReviews < ActiveRecord::Migration[4.2]
  def change
    create_table :date_suggestions_comparison_reviews do |t|
      t.integer :julie_action_id
      t.text :comment
      t.timestamps

      t.index :julie_action_id
    end
  end
end
