class AddMissingColumnsToAutoMessageClassifications < ActiveRecord::Migration
  def change
    add_column :auto_message_classifications, :annotated_reply, :text
    add_column :auto_message_classifications, :language_level, :string
  end
end
