class AddReminderDateToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :follow_up_reminder_date, :datetime
  end
end
