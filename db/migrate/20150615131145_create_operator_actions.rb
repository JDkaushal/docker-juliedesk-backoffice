class CreateOperatorActions < ActiveRecord::Migration
  def up
    create_table :operator_actions do |t|
      t.column :target_id, :integer
      t.column :target_type, :string
      t.column :operator_id, :integer
      t.column :messages_thread_id, :integer
      t.column :nature, :string
      t.column :initiated_at, :datetime
      t.timestamps
    end
  end

  def down
    drop_table :operator_actions
  end
end
