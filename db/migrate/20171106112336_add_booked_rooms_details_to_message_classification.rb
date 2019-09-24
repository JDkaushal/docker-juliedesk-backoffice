class AddBookedRoomsDetailsToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :booked_rooms_details, :json
  end
end
