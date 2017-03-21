class CreateDateSuggestionsComparisonReviews < ActiveRecord::Migration
  def change
    create_table :date_suggestions_comparison_reviews do |t|
      t.integer :julie_action_id
      t.text :comment
      t.timestamps

      t.index :julie_action_id
    end
  end
end
