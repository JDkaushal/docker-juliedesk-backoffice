class AddCallInstructionsToMessageClassifications < ActiveRecord::Migration
  def change
    add_column :message_classifications, :call_instructions, :text, default: "[]"
  end
end
