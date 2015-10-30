class CreateEventTitleReviewsTable < ActiveRecord::Migration
  def up
    create_table :event_title_reviews do |t|
      t.column :messages_thread_id, :integer
      t.column :status, :string
      t.column :title, :string
      t.timestamps
    end
  end

  def down
    drop_table :event_title_reviews
  end
end
