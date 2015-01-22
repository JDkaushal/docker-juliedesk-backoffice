class CreateJulieActionsTable < ActiveRecord::Migration
  def up
    create_table :julie_actions do |t|
      t.integer :message_id
      t.string :action_nature
      t.text :date_times
      t.text :text
      t.timestamps
    end
  end

  def down
    drop_table :julie_actions
  end
end
