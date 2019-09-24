class AddAuthenticationTokenToMessagesThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :authentication_token, :string
  end
end
