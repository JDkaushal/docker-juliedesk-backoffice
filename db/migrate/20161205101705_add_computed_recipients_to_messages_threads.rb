class AddComputedRecipientsToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :computed_recipients, :string, array: true, default: []
  end
end
