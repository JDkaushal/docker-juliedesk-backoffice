class AddTemplateModifiedColumnToJulieActions < ActiveRecord::Migration[4.2]
  def change
    add_column :julie_actions, :generated_text, :text
  end
end
