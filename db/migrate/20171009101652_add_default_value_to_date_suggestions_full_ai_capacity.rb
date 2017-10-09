class AddDefaultValueToDateSuggestionsFullAiCapacity < ActiveRecord::Migration
  def change
    change_column :julie_actions, :date_suggestions_full_ai_capacity, :boolean, default: false
  end
end
