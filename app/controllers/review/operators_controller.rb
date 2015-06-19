class Review::OperatorsController < ReviewController

  def index
    @operators = Operator.all
    oags_to_review = OperatorActionsGroup.where(review_status: MessageClassification::REVIEW_STATUS_TO_REVIEW)

    @to_review_count = oags_to_review.map(&:messages_thread_id).uniq.length

    oags_to_learn = OperatorActionsGroup.where(review_status: MessageClassification::REVIEW_STATUS_TO_LEARN)

    @oags_to_learn_counts = Hash[@operators.map{|operator|
      [
          operator.id,
          oags_to_learn.select{|oag| oag.operator_id == operator.id}.map(&:messages_thread_id).uniq.length
       ]
    }]
  end
end