class AddAiFiltersResultsToJulieAction < ActiveRecord::Migration[4.2]
  def change
    add_column :julie_actions, :ai_filters_results, :json
    change_column_default :julie_actions, :ai_filters_results, {}
  end
end
