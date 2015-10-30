class Review::OperatorsController < ReviewController

  skip_before_filter :only_admin, only: [:my_stats]
  def index
    compute_counts
  end

  def my_stats

    @operator = Operator.find session[:operator_id]
  end

  def show
    compute_counts
    if params[:id] == "all"
      @operator = nil
    else
      @operator = Operator.find params[:id]
    end
  end

  def review_list
    compute_counts
    operator_ids = Operator.where("email <> 'guillaume@juliedesk.com'").map(&:id)
    messages_thread_ids = OperatorActionsGroup.order("initiated_at ASC").where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, operator_id: operator_ids).map(&:messages_thread_id)
    @messages_threads = MessagesThread.where(id: messages_thread_ids).sort{|mt1, mt2| messages_thread_ids.index(mt1.id) <=> messages_thread_ids.index(mt2.id)}
  end

  def events_review_list
    compute_counts
    @event_title_reviews = EventTitleReview.where(status: nil).includes(messages_thread: {messages: :message_classifications}).order(:created_at)
  end

  def review_event_titles
    EventTitleReview.where(status: nil).update_all(status: EventTitleReview::STATUS_REVIEWED)
    redirect_to action: :events_review_list
  end

  private
  def compute_counts
    @operators = Operator.all
    operator_ids = Operator.where("email <> 'guillaume@juliedesk.com'").map(&:id)
    oags_to_review = OperatorActionsGroup.where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, operator_id: operator_ids)
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

    @oags_to_learn_counts['all'] = oags_to_learn.count
  end
end