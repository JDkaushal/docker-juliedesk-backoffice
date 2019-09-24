class AddThreadStatusToMessageClassifications < ActiveRecord::Migration[4.2]
  def up
    add_column :message_classifications, :thread_status, :string
  end

  def down
    remove_column :message_classifications, :thread_status
  end
end
