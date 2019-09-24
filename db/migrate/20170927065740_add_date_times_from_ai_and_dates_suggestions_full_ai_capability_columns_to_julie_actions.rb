class AddDateTimesFromAiAndDatesSuggestionsFullAiCapabilityColumnsToJulieActions < ActiveRecord::Migration[4.2]
  def change
    add_column :julie_actions, :date_times_from_ai, :json
  end
end
