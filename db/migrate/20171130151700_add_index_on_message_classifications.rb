class AddIndexOnMessageClassifications < ActiveRecord::Migration
  def change
    add_index :message_classifications, :created_at
  end
end
