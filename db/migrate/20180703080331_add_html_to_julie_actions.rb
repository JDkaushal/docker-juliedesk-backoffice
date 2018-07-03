class AddHtmlToJulieActions < ActiveRecord::Migration
  def change
    add_column :julie_actions, :html, :text
  end
end
