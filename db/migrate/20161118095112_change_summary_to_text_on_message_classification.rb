class ChangeSummaryToTextOnMessageClassification < ActiveRecord::Migration[4.2]
  def up
    change_column :message_classifications, :summary, :text
  end

  def down
    change_column :message_classifications, :summary, :string
  end
end
