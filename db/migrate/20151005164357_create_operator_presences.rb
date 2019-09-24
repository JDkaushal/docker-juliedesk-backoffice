class CreateOperatorPresences < ActiveRecord::Migration[4.2]
  def up
    create_table :operator_presences do |t|
      t.column :operator_id, :integer
      t.column :date, :datetime
      t.timestamps
    end
  end

  def down
    drop_table :operator_presences
  end
end
