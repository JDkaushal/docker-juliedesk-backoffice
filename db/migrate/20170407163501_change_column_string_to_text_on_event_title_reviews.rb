class ChangeColumnStringToTextOnEventTitleReviews < ActiveRecord::Migration
  def up
    change_column :event_title_reviews, :title, :text
  end
  def down
    change_column :event_title_reviews, :title, :string
  end
end
