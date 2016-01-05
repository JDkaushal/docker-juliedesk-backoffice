class AddFollowUpDataToMessageClassifications < ActiveRecord::Migration
  def up
    add_column :message_classifications, :follow_up_data, :text
  end

  def down
    remove_column :message_classifications, :follow_up_data
  end
end
