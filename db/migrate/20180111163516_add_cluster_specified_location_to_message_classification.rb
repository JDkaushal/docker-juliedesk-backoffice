class AddClusterSpecifiedLocationToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :cluster_specified_location, :string
  end
end
