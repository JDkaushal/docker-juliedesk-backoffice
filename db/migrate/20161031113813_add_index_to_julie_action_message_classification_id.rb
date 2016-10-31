class AddIndexToJulieActionMessageClassificationId < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :julie_actions, :message_classification_id, algorithm: :concurrently
  end
end
