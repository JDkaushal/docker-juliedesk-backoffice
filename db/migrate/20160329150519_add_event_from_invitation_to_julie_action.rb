class AddEventFromInvitationToJulieAction < ActiveRecord::Migration[4.2]
  def change
    add_column :julie_actions, :event_from_invitation, :boolean, default: false
    add_column :julie_actions, :event_from_invitation_organizer, :string
  end
end
