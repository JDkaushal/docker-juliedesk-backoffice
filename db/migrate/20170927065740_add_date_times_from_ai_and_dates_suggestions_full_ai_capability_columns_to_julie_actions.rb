class AddDateTimesFromAiAndDatesSuggestionsFullAiCapabilityColumnsToJulieActions < ActiveRecord::Migration
  def change
    add_column :julie_actions, :date_times_from_ai, :json
    add_column :julie_actions, :date_suggestions_full_ai_capacity, :boolean
  end
end
