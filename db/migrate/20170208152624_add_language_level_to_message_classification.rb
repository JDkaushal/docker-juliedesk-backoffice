class AddLanguageLevelToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :language_level, :string
  end
end
