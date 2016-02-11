class Review::OperatorsController < ReviewController

  skip_before_filter :only_super_operator_level_2_or_admin, only: [:my_stats]
  before_filter :only_admin, only: [:index, :show]

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
    if params[:operator_id]
      operator_ids = [params[:operator_id]]
    end
    operator_action_groups = OperatorActionsGroup.order("initiated_at ASC").where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, operator_id: operator_ids)

    messages_thread_ids = operator_action_groups.map(&:messages_thread_id)
    @created_events_messages_thread_ids = operator_action_groups.where(label: "ask_create_event").map(&:messages_thread_id)

    @messages_threads = MessagesThread.where(id: messages_thread_ids).sort{|mt1, mt2| messages_thread_ids.index(mt1.id) <=> messages_thread_ids.index(mt2.id)}
  end

  def events_review_list
    compute_counts
    @event_title_reviews = EventTitleReview.where(status: nil).includes(messages_thread: {messages: {message_classifications: :julie_action}}).order(:created_at)
  end

  def review_event_titles
    EventTitleReview.where(status: nil).update_all(status: EventTitleReview::STATUS_REVIEWED)
    redirect_to action: :events_review_list
  end

  def review_dashboard
    operator_actions = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 30.days)
    reviewed_count = operator_actions.where(review_status: ["reviewed", "learnt", "to_learn"]).count
    total_count = operator_actions.count

    operator_actions_week = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 7.days)
    reviewed_count_week = operator_actions_week.where(review_status: ["reviewed", "learnt", "to_learn"]).count
    total_count_week = operator_actions_week.count

    counts_by_operator = operator_actions.group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_reviewed = operator_actions.where(review_status: ["reviewed", "learnt", "to_learn"]).group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_errors = operator_actions.where(review_status: ["reviewed", "learnt", "to_learn"], review_notation: [0, 1, 2, 3, 4]).group(:operator_id).select("COUNT(*), operator_id")

    result = EmailServer.search_messages({
                                    after: (DateTime.now - 30.days).to_s,
                                    labels: "flag",
                                    limit: 1000
                                })

    flag_server_message_ids = result['messages']['ids']
    flag_messages_thread_ids = Message.where(server_message_id: flag_server_message_ids).order(:created_at).select(:messages_thread_id).map(&:messages_thread_id)

    flag_count = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 30.days).where(review_status: nil, messages_thread_id: flag_messages_thread_ids).count

    @data = {
        main_coverage: reviewed_count * 1.0 / total_count,
        review_count: reviewed_count,
        review_messages_thread_ids: operator_actions.where("initiated_at < ?", DateTime.now - 1.days).order(initiated_at: :desc).limit(10).select(:messages_thread_id).map(&:messages_thread_id),
        main_coverage_week: reviewed_count_week * 1.0 / total_count_week,
        review_count_week: reviewed_count_week,
        flag_to_review_count: flag_count,
        flag_to_review_messages_thread_ids: flag_messages_thread_ids.first(10),
        operators: Operator.where(enabled: true).where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2]).sort_by(&:level).map { |operator|

          {
              id: operator.id,
              name: operator.name,
              level: operator.level_string,
              coverage: counts_by_operator_reviewed.select{|c| c['operator_id'] == operator.id}.first['count'] * 1.0 / counts_by_operator.select{|c| c['operator_id'] == operator.id}.first['count'],
              errors_percentage: (counts_by_operator_errors.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count') || 0) * 1.0 / counts_by_operator_reviewed.select{|c| c['operator_id'] == operator.id}.first['count'],
          }
        }
    }
  end

  def messages_thread_ids_to_review_for_operator
    messages_thread_ids = OperatorActionsGroup.where("initiated_at < ?", DateTime.now - 1.days).where(review_status: nil, operator_id: params[:operator_id]).order(initiated_at: :desc).limit(3).select(:messages_thread_id).map(&:messages_thread_id)

    render json: {
               status: "success",
               data: {
                   messages_thread_ids: messages_thread_ids
               }
           }
  end

  private
  def compute_counts
    @operators = Operator.all
    operator_ids = Operator.where("email <> 'guillaume@juliedesk.com'").map(&:id)

    oags_to_review = OperatorActionsGroup.where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, operator_id: operator_ids)
    oags_to_group_review = OperatorActionsGroup.where(group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)


    @to_review_count = oags_to_review.map(&:messages_thread_id).uniq.length

    @oags_to_review_counts = Hash[@operators.map{|operator|
                                   [
                                       operator.id,
                                       oags_to_review.select{|oag| oag.operator_id == operator.id}.map(&:messages_thread_id).uniq.length
                                   ]
                                 }]

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