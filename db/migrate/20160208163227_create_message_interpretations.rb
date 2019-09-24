class CreateMessageInterpretations < ActiveRecord::Migration[4.2]
  def up
    create_table :message_interpretations do |t|
      t.column :question, :string
      t.column :raw_response, :text
      t.column :message_id, :integer
      t.timestamps
    end
  end

  def down
    drop_table :message_interpretations
  end
end
