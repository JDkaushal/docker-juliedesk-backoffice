class AddTemplateKindToJulieActions < ActiveRecord::Migration
  def change
    add_column :julie_actions, :template_kind, :string
  end
end
