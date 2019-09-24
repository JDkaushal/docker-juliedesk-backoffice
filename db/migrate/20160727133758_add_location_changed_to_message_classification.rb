class AddLocationChangedToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :location_changed, :boolean
  end
end
