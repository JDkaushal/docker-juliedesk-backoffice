class AddVirtualResourceIdUsedToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :virtual_resource_used, :json
  end
end
