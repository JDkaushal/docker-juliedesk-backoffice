class AddLinkedAttendeesToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :linked_attendees, :json, default: {}
  end
end
