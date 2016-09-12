class AddVirtualResourceIdUsedToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :virtual_resource_used, :json
  end
end
