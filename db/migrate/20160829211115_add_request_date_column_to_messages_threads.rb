class AddRequestDateColumnToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :request_date, :datetime
  end
end
