class AddIndexOnMessageClassifications < ActiveRecord::Migration[4.2]
  def change
    add_index :message_classifications, :created_at
  end
end
