class AddBeforeUpdateEventDataToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :before_update_data, :json
  end
end
