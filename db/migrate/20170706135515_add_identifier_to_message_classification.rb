class AddIdentifierToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :identifier, :string
    add_index :message_classifications, :identifier
  end
end
