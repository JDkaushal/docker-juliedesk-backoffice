class CreateEventAttendeesStagingTables < ActiveRecord::Migration[4.2]

  def change
    if ENV['STAGING_APP']
      create_table :staging_event_attendees do |t|
        t.column :event_id, :string
        t.column :attendees, :text
        t.timestamps
      end
    end
  end
end
