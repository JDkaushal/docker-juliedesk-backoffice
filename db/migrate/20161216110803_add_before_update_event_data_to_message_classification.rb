class AddBeforeUpdateEventDataToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :before_update_data, :json
  end
end
