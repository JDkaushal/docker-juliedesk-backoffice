class AddLinkedAttendeesToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :linked_attendees, :json, default: {}
  end
end
