class CreateMessageClassificationsTable < ActiveRecord::Migration
  def up
    create_table :message_classifications do |t|
      t.string :classification
      t.integer :message_id
      t.string :operator
      t.boolean :validated, default: false


      t.string :appointment_nature
      t.string :summary
      t.integer :duration
      t.text :location
      t.text :attendees, default: "[]"
      t.text :notes
      t.text :constraints

      t.text :date_times, default: "[]"

      t.timestamps
    end
  end

  def down
    drop_table :message_classifications
  end
end
