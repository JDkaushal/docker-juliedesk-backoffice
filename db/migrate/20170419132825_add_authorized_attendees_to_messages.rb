class AddAuthorizedAttendeesToMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :messages, :allowed_attendees, :string, array: true, default: []
  end
end
