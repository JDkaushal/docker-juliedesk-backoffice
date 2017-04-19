class AddAuthorizedAttendeesToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :allowed_attendees, :string, array: true, default: []
  end
end
