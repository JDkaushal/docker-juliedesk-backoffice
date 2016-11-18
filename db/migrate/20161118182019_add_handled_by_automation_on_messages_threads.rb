class AddHandledByAutomationOnMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :handled_by_automation, :boolean, default: false
  end
end
