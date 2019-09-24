class CreateAutoMessageClassifications < ActiveRecord::Migration[4.2]
  def change
    create_table :auto_message_classifications do |t|
      t.string   "classification"
      t.integer  "message_id"
      t.string   "operator"
      t.boolean  "validated",                  default: false
      t.string   "appointment_nature"
      t.text     "summary"
      t.integer  "duration"
      t.text     "location"
      t.text     "attendees",                  default: "[]"
      t.text     "notes"
      t.text     "constraints"
      t.text     "date_times",                 default: "[]"
      t.string   "locale"
      t.string   "timezone"
      t.integer  "processed_in"
      t.string   "location_nature"
      t.boolean  "private",                    default: false
      t.text     "other_notes"
      t.text     "constraints_data",           default: "[]"
      t.boolean  "client_agreement",           default: false
      t.boolean  "attendees_are_noticed",      default: false
      t.text     "number_to_call"
      t.string   "review_status"
      t.text     "call_instructions",          default: "[]"
      t.string   "thread_status"
      t.text     "follow_up_data"
      t.string   "title_preference"
      t.json     "location_coordinates",       default: []
      t.boolean  "using_meeting_room",         default: false
      t.json     "meeting_room_details"
      t.boolean  "using_restaurant_booking",   default: false
      t.json     "restaurant_booking_details"
      t.boolean  "location_changed"
      t.json     "virtual_resource_used"
      t.json     "before_update_data"
      t.integer  "notation"
      t.text     "notation_tags"
      t.text     "notation_comments"
      t.boolean  "from_ai",                    default: true
      t.timestamps
    end
  end
end
