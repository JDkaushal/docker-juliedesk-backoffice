class AddNeedAiConfirmationToClientContacts < ActiveRecord::Migration
  def change
    add_column :client_contacts, :need_ai_confirmation, :boolean, default: false
  end
end
