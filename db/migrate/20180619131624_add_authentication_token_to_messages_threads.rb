class AddAuthenticationTokenToMessagesThreads < ActiveRecord::Migration
  def change
    add_column :messages_threads, :authentication_token, :string
  end
end
