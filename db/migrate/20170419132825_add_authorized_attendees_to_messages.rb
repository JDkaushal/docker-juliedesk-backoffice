class AddAuthorizedAttendeesToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :allowed_attendees, :string, array: true, default: []
  end
end
