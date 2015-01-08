class CreateEventsTable < ActiveRecord::Migration
  def up
    create_table :events do |t|
      t.string :email
      t.string :calendar_nature
      t.text :event_id
      t.text :calendar_id
      t.string :classification

      t.timestamps
    end
  end

  def down
    drop_table :events
  end
end
