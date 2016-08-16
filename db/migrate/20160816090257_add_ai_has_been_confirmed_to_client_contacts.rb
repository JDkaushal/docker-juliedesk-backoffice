class AddAiHasBeenConfirmedToClientContacts < ActiveRecord::Migration
  def change
    add_column :client_contacts, :ai_has_been_confirmed, :boolean, default: false
  end
end
