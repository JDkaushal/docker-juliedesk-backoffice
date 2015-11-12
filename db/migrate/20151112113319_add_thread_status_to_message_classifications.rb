class AddThreadStatusToMessageClassifications < ActiveRecord::Migration
  def up
    add_column :message_classifications, :thread_status, :string
  end

  def down
    remove_column :message_classifications, :thread_status
  end
end
