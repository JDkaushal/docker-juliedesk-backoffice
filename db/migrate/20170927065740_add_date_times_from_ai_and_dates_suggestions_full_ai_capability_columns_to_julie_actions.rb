class AddDateTimesFromAiAndDatesSuggestionsFullAiCapabilityColumnsToJulieActions < ActiveRecord::Migration
  def change
    add_column :julie_actions, :date_times_from_ai, :json
  end
end
