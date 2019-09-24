class AddAccountAssociationMergingPossibleToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :account_association_merging_possible, :boolean, default: false
  end
end
