class AddAuthorizedAttendeesToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :allowed_attendees, :string, array: true, default: []
  end
end
