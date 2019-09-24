class AddClientOnTripToMessageClassifications < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :client_on_trip, :json
    add_column :auto_message_classifications, :client_on_trip, :json
  end
end
