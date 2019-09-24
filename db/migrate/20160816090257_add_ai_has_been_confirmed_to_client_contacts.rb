class AddAiHasBeenConfirmedToClientContacts < ActiveRecord::Migration[4.2]
  def change
    add_column :client_contacts, :ai_has_been_confirmed, :boolean, default: false
  end
end
