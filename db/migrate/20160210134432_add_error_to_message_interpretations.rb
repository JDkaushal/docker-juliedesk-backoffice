class AddErrorToMessageInterpretations < ActiveRecord::Migration[4.2]
  def up
    add_column :message_interpretations, :error, :boolean
  end

  def down
    remove_column :message_interpretations, :error
  end
end
