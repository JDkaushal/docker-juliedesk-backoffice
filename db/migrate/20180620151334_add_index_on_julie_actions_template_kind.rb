class AddIndexOnJulieActionsTemplateKind < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :julie_actions, :template_kind, algorithm: :concurrently
  end
end
