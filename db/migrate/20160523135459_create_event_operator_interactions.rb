class CreateEventOperatorInteractions < ActiveRecord::Migration[4.2]
  def change
    create_table :event_operator_interactions do |t|
      t.json :event_infos
      t.json :modifications_done
      t.integer :operator_id
      t.datetime :done_at

      t.timestamps
    end
  end
end
