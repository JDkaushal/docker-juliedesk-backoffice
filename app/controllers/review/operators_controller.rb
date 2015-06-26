class Review::OperatorsController < ReviewController

  def index
    compute_counts
  end

  def show
    compute_counts
    @operator = Operator.find params[:id]

  end

  private
  def compute_counts
    @operators = Operator.all
    oags_to_review = OperatorActionsGroup.where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW)
    oags_to_group_review = OperatorActionsGroup.where(group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)

    @to_review_count = oags_to_review.map(&:messages_thread_id).uniq.length
    @to_group_review_count = oags_to_group_review.map(&:messages_thread_id).uniq.length

    oags_to_learn = OperatorActionsGroup.where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN)

    @oags_to_learn_counts = Hash[@operators.map{|operator|
      [
          operator.id,
          oags_to_learn.select{|oag| oag.operator_id == operator.id}.map(&:messages_thread_id).uniq.length
      ]
    }]
  end
end