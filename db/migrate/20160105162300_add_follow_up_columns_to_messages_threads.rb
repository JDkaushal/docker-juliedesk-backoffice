class AddFollowUpColumnsToMessagesThreads < ActiveRecord::Migration
  def up
    add_column :messages_threads, :should_follow_up, :boolean, default: false
    add_column :messages_threads, :follow_up_instruction, :text
  end

  def down
    remove_column :messages_threads, :should_follow_up
    remove_column :messages_threads, :follow_up_instruction, :text
  end
end
