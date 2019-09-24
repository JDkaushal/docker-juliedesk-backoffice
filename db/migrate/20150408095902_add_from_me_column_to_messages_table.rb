class AddFromMeColumnToMessagesTable < ActiveRecord::Migration[4.2]
  def up
    add_column :messages, :from_me, :boolean, default: false
  end

  def down
    remove_column :messages, :from_me
  end
end
