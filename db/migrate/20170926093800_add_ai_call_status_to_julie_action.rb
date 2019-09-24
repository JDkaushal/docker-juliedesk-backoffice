class AddAiCallStatusToJulieAction < ActiveRecord::Migration[4.2]
  def change
    add_column :julie_actions, :ai_call_status, :json
  end
end
