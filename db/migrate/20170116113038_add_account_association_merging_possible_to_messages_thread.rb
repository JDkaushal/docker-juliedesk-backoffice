class AddAccountAssociationMergingPossibleToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :account_association_merging_possible, :boolean, default: false
  end
end
