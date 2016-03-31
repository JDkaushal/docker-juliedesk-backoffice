class AddTitlePreferenceToMessageClassification < ActiveRecord::Migration
  def change
    add_column :message_classifications, :title_preference, :string
  end
end
