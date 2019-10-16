class AddLocationCoordinatesToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :location_coordinates, :json, default: []
  end
end
