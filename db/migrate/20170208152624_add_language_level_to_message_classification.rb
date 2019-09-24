class AddLanguageLevelToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :language_level, :string
  end
end
