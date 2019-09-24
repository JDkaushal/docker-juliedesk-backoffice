class AddVerifiedDatesbyAiToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :verified_dates_by_ai, :json
  end
end
