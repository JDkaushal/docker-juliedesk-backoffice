class AddNeedAiConfirmationToClientContacts < ActiveRecord::Migration[4.2]
  def change
    add_column :client_contacts, :need_ai_confirmation, :boolean, default: false
  end
end
