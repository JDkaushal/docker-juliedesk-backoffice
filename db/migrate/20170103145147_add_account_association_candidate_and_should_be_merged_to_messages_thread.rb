class AddAccountAssociationCandidateAndShouldBeMergedToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :accounts_candidates, :string, default: [], array: true
  end
end
