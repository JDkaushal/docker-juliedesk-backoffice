class AddAiCallStatusToJulieAction < ActiveRecord::Migration
  def change
    add_column :julie_actions, :ai_call_status, :json
  end
end
