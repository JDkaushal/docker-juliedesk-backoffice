class AddDateSuggestionsFullAiColumnsToJulieActions < ActiveRecord::Migration[4.2]
  def change
    add_column :julie_actions, :date_suggestions_full_ai, :boolean, default: false
  end
end
