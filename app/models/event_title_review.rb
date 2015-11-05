class EventTitleReview < ActiveRecord::Base

  belongs_to :messages_thread

  STATUS_REVIEWED = "reviewed"
end