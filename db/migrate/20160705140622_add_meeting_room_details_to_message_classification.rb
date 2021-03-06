class AddMeetingRoomDetailsToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :using_meeting_room, :boolean, default: false
    add_column :message_classifications, :meeting_room_details, :json
  end
end
