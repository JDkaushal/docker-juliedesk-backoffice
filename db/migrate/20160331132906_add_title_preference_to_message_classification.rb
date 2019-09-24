class AddTitlePreferenceToMessageClassification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :title_preference, :string
  end
end
