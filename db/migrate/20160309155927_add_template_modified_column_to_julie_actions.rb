class AddTemplateModifiedColumnToJulieActions < ActiveRecord::Migration
  def change
    add_column :julie_actions, :generated_text, :text
  end
end
