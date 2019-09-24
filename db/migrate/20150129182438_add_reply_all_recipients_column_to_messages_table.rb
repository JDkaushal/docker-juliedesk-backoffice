class AddReplyAllRecipientsColumnToMessagesTable < ActiveRecord::Migration[4.2]
  def up
    add_column :messages, :reply_all_recipients, :text
  end

  def down
    remove_column :messages, :reply_all_recipients
  end
end
