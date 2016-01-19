class CreateStagingServerMessagesTable < ActiveRecord::Migration

  def change
    if ENV['STAGING_APP']
      create_table :staging_server_messages do |t|
        t.column :messages_thread_id, :integer
        t.column :server_message, :text
        t.timestamps
      end
    end
  end
end
