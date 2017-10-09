class AddDateTimesFromAiAndDatesSuggestionsFullAiCapabilityColumnsToJulieActions2 < ActiveRecord::Migration
  def change
    add_column :julie_actions, :date_suggestions_full_ai_capacity, :boolean
  end
end
