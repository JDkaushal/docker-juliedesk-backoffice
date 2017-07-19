class AddPassedConditionsToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :passed_conditions, :json
  end
end
