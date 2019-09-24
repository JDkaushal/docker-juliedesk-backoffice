class AddTemplateKindToJulieActions < ActiveRecord::Migration[4.2]
  def change
    add_column :julie_actions, :template_kind, :string
  end
end
