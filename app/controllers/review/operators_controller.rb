class Review::OperatorsController < ReviewController

  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  skip_before_filter :only_super_operator_level_2_or_admin, only: [:my_stats, :my_errors]

  def my_stats
    @operator = Operator.find session[:operator_id]
    @previous_errors_count = @operator.operator_actions_groups.where('review_notation < ?', 5).size

    @errors_url = my_errors_review_operators_path
  end

  def my_errors
    @operator = Operator.find session[:operator_id]
    operator_errors = OperatorActionsGroup.where(operator_id: session[:operator_id]).where('review_notation < ?', 5)

    smart_listing_create(:operator_errors, operator_errors, partial: "review/operators/listings/errors", default_sort: {created_at: "desc"}, page_sizes: [50])
  end

  def errors
    @operator = Operator.find(params[:id])
    operator_errors = OperatorActionsGroup.where(operator_id: @operator.id).where('review_notation < ?', 5)
    @review_mode = true
    smart_listing_create(:operator_errors, operator_errors, partial: "review/operators/listings/errors", default_sort: {created_at: "desc"}, page_sizes: [50])

    render 'my_errors'
  end

  def show
    if params[:id] == "all"
      @operator = nil
    else
      @operator = Operator.find params[:id]
      @previous_errors_count = @operator.operator_actions_groups.where('review_notation < ?', 5).size
      @errors_url = errors_review_operator_path(@operator)
    end

  end

  def index
    reference_date_month = DateTime.now - 30.days

    operator_actions = OperatorActionsGroup.where("initiated_at > ?", reference_date_month)
    reviewed_count = operator_actions.where(review_status: ["reviewed", "learnt", "to_learn"]).count
    total_count = operator_actions.count

    operator_actions_week = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 7.days)
    reviewed_count_week = operator_actions_week.where(review_status: ["reviewed", "learnt", "to_learn"]).count
    total_count_week = operator_actions_week.count

    counts_by_operator = operator_actions.group(:operator_id).select("COUNT(*), operator_id")
    total_duration_by_operator = operator_actions.group(:operator_id).select("SUM(duration), operator_id")
    counts_by_operator_reviewed = operator_actions.where(review_notation: [0, 1, 2, 3, 4, 5]).group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_errors = operator_actions.where(review_notation: [0, 1, 2, 3]).group(:operator_id).select("COUNT(*), operator_id")

    result = EmailServer.search_messages({
                                    after: (reference_date_month).to_s,
                                    labels: "flag",
                                    limit: 1000
                                })

    flag_server_message_ids = result['messages']['ids']
    flag_messages_thread_ids = Message.where(server_message_id: flag_server_message_ids).order(:created_at).select(:messages_thread_id).map(&:messages_thread_id).uniq
    flag_count = OperatorActionsGroup.where("initiated_at > ?", reference_date_month).where("initiated_at < ?", DateTime.now - 1.days).where(review_status: nil, messages_thread_id: flag_messages_thread_ids).count

    total_errors_count_for_all_operators = counts_by_operator_errors.inject(0) {|sum, oa| sum + oa.count}

    operators_data = Operator.where(enabled: true).where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2]).sort_by(&:level).map { |operator|
      actions_count = counts_by_operator.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count')
      errors_count = counts_by_operator_errors.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count')
      total_duration_in_seconds = operator.operator_presences.where('date >= ?', reference_date_month).count * 30 * 60 # Each presence is equivalent to 30 minutes so we multiply the count by 30 then by 60 to have it in seconds

      {
          id: operator.id,
          name: operator.name,
          level: operator.level_string,
          actions_count: actions_count,
          coverage: (counts_by_operator_reviewed.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count') || 0) * 1.0 / (actions_count || 1),
          errors_percentage: (errors_count || 0) * 1.0 / (actions_count || 1),
          errors_percentage_global: (errors_count || 0) * 1.0 / (total_errors_count_for_all_operators || 1),
          errors_count: errors_count,
          total_duration_in_seconds: total_duration_in_seconds,
          mails_treatment_hourly_flow: (actions_count || 0) / (total_duration_in_seconds.to_f / 3600)
      }
    }

    if params['sort'].present?
      operators_data = sort_operators_data(params['sort'], operators_data)
    end

    total_errors_count_for_all_operators = counts_by_operator_errors.inject(0) {|sum, oa| sum + oa.count}

    operators_data = Operator.where(enabled: true).where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2]).sort_by(&:level).map { |operator|
      actions_count = counts_by_operator.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count')
      errors_count = counts_by_operator_errors.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count')
      total_duration_in_seconds = total_duration_by_operator.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'sum')

      {
          id: operator.id,
          name: operator.name,
          level: operator.level_string,
          actions_count: actions_count,
          coverage: (counts_by_operator_reviewed.select{|c| c['operator_id'] == operator.id}.first.try(:[], 'count') || 0) * 1.0 / (actions_count || 1),
          errors_percentage: (errors_count || 0) * 1.0 / (actions_count || 1),
          errors_percentage_global: (errors_count || 0) * 1.0 / (total_errors_count_for_all_operators || 1),
          errors_count: errors_count,
          total_duration_in_seconds: total_duration_in_seconds,
          mails_treatment_hourly_flow: (actions_count || 0) / (total_duration_in_seconds.to_f / 3600)
      }
    }

    if params['sort'].present?
      operators_data = sort_operators_data(params['sort'], operators_data)
    end

    @data = {
        main_coverage: reviewed_count * 1.0 / total_count,
        review_count: reviewed_count,
        main_coverage_week: reviewed_count_week * 1.0 / total_count_week,
        review_count_week: reviewed_count_week,
        flag_to_review_count: flag_count,
        to_group_review_count: OperatorActionsGroup.where(group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN).count,
        total_count: total_count,
        total_duration_for_all_operators_in_seconds: total_duration_by_operator.inject(0) {|sum, oa| sum + oa.sum},
        total_percentage_coverage_for_all_operators: counts_by_operator_reviewed.inject(0) {|sum, oa| sum + oa.count}.to_f / total_count,
        total_errors_count_for_all_operators: total_errors_count_for_all_operators,
        total_errors_percentage_for_all_operators: total_errors_count_for_all_operators.to_f / total_count,
        operators: operators_data
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


  private

  def sort_operators_data(sorting_details, operators_data)
    attribute_to_sort = sorting_details['attribute']
    sorting_direction = sorting_details['direction'] == 'asc' ? 1 : -1

    operators_data.sort_by do |datum|
      sort_number = if datum[attribute_to_sort.to_sym].is_a?(Float) && datum[attribute_to_sort.to_sym].nan?
                      Float::INFINITY
                    else
                      (datum[attribute_to_sort.to_sym] || 0)
                    end

      sort_number * sorting_direction
    end
  end
end
