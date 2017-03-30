class AddAsapConstraintColumnToMessageClassifications < ActiveRecord::Migration
  def change
    add_column :message_classifications, :asap_constraint, :boolean, default: false
    add_column :auto_message_classifications, :asap_constraint, :boolean, default: false
  end
end
