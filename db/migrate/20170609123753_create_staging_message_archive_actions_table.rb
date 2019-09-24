class CreateStagingMessageArchiveActionsTable < ActiveRecord::Migration[4.2]

  def change
    if ENV['STAGING_APP']
      create_table :staging_messages_thread_archive_actions do |t|
        t.integer :messages_thread_id
        t.boolean :currently_archived
      end
    end
  end
end
