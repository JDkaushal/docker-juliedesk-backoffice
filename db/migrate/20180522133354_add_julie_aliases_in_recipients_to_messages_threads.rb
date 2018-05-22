class AddJulieAliasesInRecipientsToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :julie_aliases_in_recipients, :string, array: true, default: []
  end
end
