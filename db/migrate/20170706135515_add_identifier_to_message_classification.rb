class AddIdentifierToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :identifier, :string
    add_index :message_classifications, :identifier
  end
end
