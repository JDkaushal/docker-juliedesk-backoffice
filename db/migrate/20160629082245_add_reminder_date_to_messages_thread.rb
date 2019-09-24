class AddReminderDateToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :follow_up_reminder_date, :datetime
  end
end
