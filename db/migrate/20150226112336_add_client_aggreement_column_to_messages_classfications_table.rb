class AddClientAggreementColumnToMessagesClassficationsTable < ActiveRecord::Migration
  def up
    add_column :message_classifications, :client_agreement, :boolean, default: false
  end

  def down
    remove_column :message_classifications, :client_agreement
  end
end
