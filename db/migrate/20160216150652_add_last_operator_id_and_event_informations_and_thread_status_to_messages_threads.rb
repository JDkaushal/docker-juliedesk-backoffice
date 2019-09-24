class AddLastOperatorIdAndEventInformationsAndThreadStatusToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :last_operator_id, :integer
    add_column :messages_threads, :event_booked_date, :datetime
    add_column :messages_threads, :status, :string
  end
end
