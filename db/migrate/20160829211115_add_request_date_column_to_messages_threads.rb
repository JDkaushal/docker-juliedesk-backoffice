class AddRequestDateColumnToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :request_date, :datetime
  end
end
