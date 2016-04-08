class Review::OperatorsController < ReviewController

  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  skip_before_filter :only_super_operator_level_2_or_admin, only: [:my_stats]

  def my_stats
    @operator = Operator.find session[:operator_id]
    @previous_errors_count = @operator.operator_actions_groups.where('review_notation < ?', 5).size
  end

  def my_errors
    @operator = Operator.find session[:operator_id]
    operator_errors = OperatorActionsGroup.where(operator_id: session[:operator_id]).where('review_notation < ?', 5)

    smart_listing_create(:operator_errors, operator_errors, partial: "review/operators/listings/errors", default_sort: {created_at: "desc"}, page_sizes: [50])
  end

  def show
    if params[:id] == "all"
      @operator = nil
    else
      @operator = Operator.find params[:id]
    end
  end

  def index
    operator_actions = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 30.days)
    reviewed_count = operator_actions.where(review_status: ["reviewed", "learnt", "to_learn"]).count
    total_count = operator_actions.count

    operator_actions_week = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 7.days)
    reviewed_count_week = operator_actions_week.where(review_status: ["reviewed", "learnt", "to_learn"]).count
    total_count_week = operator_actions_week.count

    counts_by_operator = operator_actions.group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_reviewed = operator_actions.where(review_notation: [0, 1, 2, 3, 4, 5]).group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_errors = operator_actions.where(review_notation: [0, 1, 2, 3]).group(:operator_id).select("COUNT(*), operator_id")


    result = EmailServer.search_messages({
                                    after: (DateTime.now - 30.days).to_s,
                                    labels: "flag",
                                    limit: 1000
                                })

    flag_server_message_ids = result['messages']['ids']
    flag_messages_thread_ids = Message.where(server_message_id: flag_server_message_ids).order(:created_at).select(:messages_thread_id).map(&:messages_thread_id).uniq
    flag_count = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 30.days).where("initiated_at < ?", DateTime.now - 1.days).where(review_status: nil, messages_thread_id: flag_messages_thread_ids).count

    @data = {
        main_coverage: reviewed_count * 1.0 / total_count,
        review_count: reviewed_count,
        main_coverage_week: reviewed_count_week * 1.0 / total_count_week,
        review_count_week: reviewed_count_week,
        flag_to_review_count: flag_count,
        to_group_review_count: OperatorActionsGroup.where(group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN).count,
        total_count: total_count,
        operators: Operator.where(enabled: true).where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2]).sort_by(&:level).map { |operator|

          {
              id: operator.id,
              name: operator.name,
              level: operator.level_string,
              actions_count: counts_by_operator.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count'),
              coverage: (counts_by_operator_reviewed.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count') || 0) * 1.0 / (counts_by_operator.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count') || 1),
              errors_percentage: (counts_by_operator_errors.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count') || 0) * 1.0 / (counts_by_operator_reviewed.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count') || 1),
          }
        }
    }
  end

  def messages_thread_ids_to_review
    operator_actions = OperatorActionsGroup
                           .where("initiated_at > ?", DateTime.now - 30.days)
                           .where("initiated_at < ?", DateTime.now - 1.days)
                           .where(review_status: nil)




    if params[:mode] == "flag"
      result = EmailServer.search_messages({
                                               after: (DateTime.now - 30.days).to_s,
                                               labels: "flag",
                                               limit: 1000
                                           })

      flag_server_message_ids = result['messages']['ids']
      flag_messages_thread_ids = Message.where(server_message_id: flag_server_message_ids).select(:messages_thread_id).map(&:messages_thread_id).uniq
      operator_actions = operator_actions.where(messages_thread_id: flag_messages_thread_ids)
    elsif params[:mode] == "operator"
      operator_actions = operator_actions.where(operator_id: params[:operator_id])
    end

    messages_thread_ids = operator_actions
                              .order(initiated_at: :desc)
                              .select(:messages_thread_id)
                              .map(&:messages_thread_id)
                              .uniq
                              .first(5)



        render json: {
               status: "success",
               data: {
                   messages_thread_ids: messages_thread_ids
               }
           }
  end
end