class AddHtmlToJulieActions < ActiveRecord::Migration[4.2]
  def change
    add_column :julie_actions, :html, :text
  end
end
