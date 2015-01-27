class CreateJulieActionsTable < ActiveRecord::Migration
  def up
    create_table :julie_actions do |t|
      t.integer :message_classification_id
      t.string :action_nature
      t.text :date_times, default: "[]"
      t.text :event_ids, default: "[]"
      t.text :text
      t.boolean :done, default: false
      t.boolean :pending, default: false
      t.timestamps
    end
  end

  def down
    drop_table :julie_actions
  end
end
