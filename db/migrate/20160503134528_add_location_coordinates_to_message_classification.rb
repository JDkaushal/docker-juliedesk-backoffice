class AddLocationCoordinatesToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :location_coordinates, :json, default: '[]'
  end
end
