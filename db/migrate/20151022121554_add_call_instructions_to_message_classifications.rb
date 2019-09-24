class AddCallInstructionsToMessageClassifications < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :call_instructions, :text, default: "[]"
  end
end
