class AutoMessageClassificationReview < ActiveRecord::Base
  belongs_to :auto_message_classification
  belongs_to :operator

end