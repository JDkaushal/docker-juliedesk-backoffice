class AddIndexOnJulieActionsTemplateKind < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :julie_actions, :template_kind, algorithm: :concurrently
  end
end
