class AddComputedRecipientsToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :computed_recipients, :string, array: true, default: []
  end
end
