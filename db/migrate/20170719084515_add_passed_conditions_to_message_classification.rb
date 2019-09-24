class AddPassedConditionsToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :passed_conditions, :json
  end
end
