class DropEventsTable < ActiveRecord::Migration
  def change
    drop_table :events do |t|
      t.string   "email"
      t.string   "calendar_nature"
      t.text     "event_id"
      t.text     "calendar_id"
      t.string   "classification"
      t.timestamps null: false
    end
  end
end
