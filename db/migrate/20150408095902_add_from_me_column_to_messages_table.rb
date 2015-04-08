class AddFromMeColumnToMessagesTable < ActiveRecord::Migration
  def up
    add_column :messages, :from_me, :boolean, default: false
  end

  def down
    remove_column :messages, :from_me
  end
end
