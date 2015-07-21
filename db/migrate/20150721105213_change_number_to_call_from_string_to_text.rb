class ChangeNumberToCallFromStringToText < ActiveRecord::Migration
  def up
    change_column :message_classifications, :number_to_call, :text
  end

  def down
    add_column :message_classifications, :temp_number_to_call, :string
    MessageClassification.find_each do |message_classification|
      temp_number_to_call = message_classification.number_to_call
      if temp_number_to_call && temp_number_to_call.length > 255
        temp_number_to_call = temp_number_to_call[0,254]
      end
      message_classification.update_column(:temp_number_to_call, temp_number_to_call)
    end
    remove_column :message_classifications, :number_to_call
    rename_column :message_classifications, :temp_number_to_call, :number_to_call
  end
end
