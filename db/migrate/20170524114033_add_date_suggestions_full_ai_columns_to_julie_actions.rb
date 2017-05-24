class AddDateSuggestionsFullAiColumnsToJulieActions < ActiveRecord::Migration
  def change
    add_column :julie_actions, :date_suggestions_full_ai, :boolean, default: false
  end
end
