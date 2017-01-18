class AddVerifiedDatesbyAiToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :verified_dates_by_ai, :json
  end
end
