class Review::OperatorsController < ReviewController

  def index
    @operators = Operator.all
    message_classification_to_review = MessageClassification.where(review_status: MessageClassification::REVIEW_STATUS_TO_REVIEW).includes(message: :messages_thread)
    @to_review_count = message_classification_to_review.select{|mc| mc.message.try(:messages_thread_id)}.map{|mc| mc.message.messages_thread_id}.uniq.length

    message_classification_to_learn = MessageClassification.where(review_status: MessageClassification::REVIEW_STATUS_TO_LEARN).includes(message: :messages_thread)

    @message_threads_to_learn_counts = Hash[@operators.map{|operator|
      [
          operator.id,
          message_classification_to_learn.select{|mc| mc.operator == operator.email}.map{|mc| mc.message.messages_thread_id}.uniq.length
       ]
    }]
  end
end