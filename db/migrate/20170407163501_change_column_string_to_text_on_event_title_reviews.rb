class ChangeColumnStringToTextOnEventTitleReviews < ActiveRecord::Migration[4.2]
  def up
    change_column :event_title_reviews, :title, :text
  end
  def down
    change_column :event_title_reviews, :title, :string
  end
end
