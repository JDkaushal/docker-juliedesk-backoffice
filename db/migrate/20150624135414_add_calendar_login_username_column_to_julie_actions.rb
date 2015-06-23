class AddCalendarLoginUsernameColumnToJulieActions < ActiveRecord::Migration
  def up
    add_column :julie_actions, :calendar_login_username, :string
  end

  def down
    remove_column :julie_actions, :calendar_login_username
  end
end
