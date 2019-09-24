class AddClusterSpecifiedLocationToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :cluster_specified_location, :string
  end
end
