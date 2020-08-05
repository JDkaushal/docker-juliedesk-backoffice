class AddOnlineMeetingProviderToMessageClassifications < ActiveRecord::Migration[5.2]
  def change
    add_column :message_classifications, :online_meeting_provider, :string, default: nil
  end
end
