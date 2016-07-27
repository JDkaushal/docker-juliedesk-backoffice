class AddRestaurantBookingDetailsToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :using_restaurant_booking, :boolean, default: false
    add_column :message_classifications, :restaurant_booking_details, :json
  end
end
