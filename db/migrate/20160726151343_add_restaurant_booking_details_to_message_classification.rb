class AddRestaurantBookingDetailsToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :using_restaurant_booking, :boolean, default: false
    add_column :message_classifications, :restaurant_booking_details, :json
  end
end
