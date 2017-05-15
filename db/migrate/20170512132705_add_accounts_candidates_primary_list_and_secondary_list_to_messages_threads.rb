class AddAccountsCandidatesPrimaryListAndSecondaryListToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :accounts_candidates_primary_list, :string , array: true, default: []
    add_column :messages_threads, :accounts_candidates_secondary_list, :string , array: true, default: []
    add_column :messages_threads, :merging_account_candidates, :string, array: true, default: []
  end
end
