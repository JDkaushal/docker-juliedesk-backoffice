class AddHandledByAutomationOnMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :handled_by_automation, :boolean, default: false
  end
end
