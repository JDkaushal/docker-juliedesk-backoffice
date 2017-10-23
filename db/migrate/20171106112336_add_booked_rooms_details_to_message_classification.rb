class AddBookedRoomsDetailsToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :booked_rooms_details, :json
  end
end
