class AddLocationChangedToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :location_changed, :boolean
  end
end
