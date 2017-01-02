class AddAccountAssociationCandidateAndShouldBeMergedToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :accounts_candidates, :string, default: [], array: true
  end
end
