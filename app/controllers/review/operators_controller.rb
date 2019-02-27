class Review::OperatorsController < ReviewController

  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  skip_before_action :only_super_operator_level_2_or_admin, only: [:my_stats, :my_errors]

  def my_stats
    @operator = Operator.find session[:operator_id]
    @previous_errors_count = @operator.operator_actions_groups.where('review_notation < ?', 5).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).size

    @errors_url = my_errors_review_operators_path
  end

  def my_errors
    @operator = Operator.find session[:operator_id]
    operator_errors = OperatorActionsGroup.where(operator_id: session[:operator_id]).where('review_notation < ?', 5)

    smart_listing_create(:operator_errors, operator_errors, partial: "review/operators/listings/errors", default_sort: {created_at: "desc"}, page_sizes: [50])
  end

  def errors
    params.permit!
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
      @previous_errors_count = @operator.operator_actions_groups.where('review_notation < ?', 5).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).size
      @errors_url = errors_review_operator_path(@operator)
    end

  end

  def index
    reference_date_month = DateTime.now - 30.days
    result = EmailServer.search_messages({ after: (reference_date_month).to_s, labels: "flag", limit: 1000 })
    flag_server_message_ids = result['messages']['ids']
    flag_messages_thread_ids = Message.where(server_message_id: flag_server_message_ids).order(:created_at).select(:messages_thread_id).map(&:messages_thread_id).uniq

    # last 30 days
    operator_actions = OperatorActionsGroup.where("initiated_at > ?", reference_date_month).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE)
    operator_actions_count = operator_actions.count

    random_actions_last_30_days_count = operator_actions.where.not(messages_thread_id: flag_messages_thread_ids).count

    random_reviews_last_30_days = operator_actions.where(review_status: ["reviewed", "learnt", "to_learn"]).where.not(messages_thread_id: flag_messages_thread_ids)
    random_review_last_30_days_count = random_reviews_last_30_days.count
    random_error_last_30_days_count = random_reviews_last_30_days.where(review_notation: [0, 1, 2, 3]).count

    flagged_reviews_last_30_days = operator_actions.where(review_status: ["reviewed", "learnt", "to_learn"], messages_thread_id: flag_messages_thread_ids)
    flagged_review_last_30_days_count = flagged_reviews_last_30_days.count
    flagged_error_last_30_days_count = flagged_reviews_last_30_days.where(review_notation: [0, 1, 2, 3]).count

    random_actions_last_30_days_percent = operator_actions_count == 0 ? nil : random_actions_last_30_days_count*1.0/operator_actions_count
    flagged_actions_last_30_days_percent = operator_actions_count == 0 ? nil : (operator_actions_count - random_actions_last_30_days_count)*1.0/operator_actions_count

    total_count_month = operator_actions.count


    # last 7 days
    operator_actions_week = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 7.days).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE)
    operator_actions_week_count = operator_actions_week.count

    random_actions_last_7_days_count = operator_actions_week.where.not(messages_thread_id: flag_messages_thread_ids).count

    random_reviews_last_7_days = operator_actions_week.where(review_status: ["reviewed", "learnt", "to_learn"]).where.not(messages_thread_id: flag_messages_thread_ids)
    random_review_last_7_days_count = random_reviews_last_7_days.count
    random_error_last_7_days_count = random_reviews_last_7_days.where(review_notation: [0, 1, 2, 3]).count

    flagged_reviews_last_7_days = operator_actions_week.where(review_status: ["reviewed", "learnt", "to_learn"], messages_thread_id: flag_messages_thread_ids)
    flagged_review_last_7_days_count = flagged_reviews_last_7_days.count
    flagged_error_last_7_days_count = flagged_reviews_last_7_days.where(review_notation: [0, 1, 2, 3]).count

    random_actions_last_7_days_percent = operator_actions_week_count == 0 ? nil : random_actions_last_7_days_count*1.0/operator_actions_week_count
    flagged_actions_last_7_days_percent = operator_actions_week_count == 0 ? nil : (operator_actions_week_count - random_actions_last_7_days_count)*1.0/operator_actions_week_count


    # current month
    operator_actions_current_month = OperatorActionsGroup.where("initiated_at > ?", DateTime.now.beginning_of_month).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE)
    operator_actions_current_month_count = operator_actions_current_month.count

    random_actions_current_month_count = operator_actions_current_month.where.not(messages_thread_id: flag_messages_thread_ids).count

    random_reviews_current_month = operator_actions_current_month.where(review_status: ["reviewed", "learnt", "to_learn"]).where.not(messages_thread_id: flag_messages_thread_ids)
    random_review_current_month_count = random_reviews_current_month.count
    random_error_current_month_count = random_reviews_current_month.where(review_notation: [0, 1, 2, 3]).count


    flagged_reviews_current_month = operator_actions_current_month.where(review_status: ["reviewed", "learnt", "to_learn"], messages_thread_id: flag_messages_thread_ids)
    flagged_review_current_month_count = flagged_reviews_current_month.count
    flagged_error_current_month_count = flagged_reviews_current_month.where(review_notation: [0, 1, 2, 3]).count

    random_actions_current_month_percent = operator_actions_current_month_count == 0 ? nil : random_actions_current_month_count*1.0/operator_actions_current_month_count
    flagged_actions_current_month_percent = operator_actions_current_month_count == 0 ? nil : (operator_actions_current_month_count - random_actions_current_month_count)*1.0/operator_actions_current_month_count



    flag_count = OperatorActionsGroup.where("initiated_at > ?", reference_date_month).where("initiated_at < ?", DateTime.now - 1.days).where(review_status: nil, messages_thread_id: flag_messages_thread_ids).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).count

    counts_by_operator = operator_actions.group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_flagged = operator_actions.where(messages_thread_id: flag_messages_thread_ids).group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_reviewed = operator_actions.where(review_notation: [0, 1, 2, 3, 4, 5]).group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_errors = operator_actions.where(review_notation: [0, 1, 2, 3]).group(:operator_id).select("COUNT(*), operator_id")

    counts_by_operator_reviewed_flagged = operator_actions.where(review_notation: [0, 1, 2, 3, 4, 5], messages_thread_id: flag_messages_thread_ids).group(:operator_id).select("COUNT(*), operator_id")
    counts_by_operator_errors_flagged = operator_actions.where(review_notation: [0, 1, 2, 3], messages_thread_id: flag_messages_thread_ids).group(:operator_id).select("COUNT(*), operator_id")

    total_errors_count_for_all_operators = counts_by_operator_errors.inject(0) { |sum, oa| sum + oa.count }

    errors_percentage_global = (
    (
    counts_by_operator_errors_flagged.map{|c| c['count']}.inject(0) { |k, v| k + v } *
        counts_by_operator_flagged.map{|c| c['count']}.inject(0) { |k, v| k + v } *
        1.0 /
        counts_by_operator_reviewed_flagged.map{|c| c['count']}.inject(0) { |k, v| k + v }
    ) +
        (
        (counts_by_operator_errors.map{|c| c['count']}.inject(0) { |k, v| k + v } - counts_by_operator_errors_flagged.map{|c| c['count']}.inject(0) { |k, v| k + v }) *
            (counts_by_operator.map{|c| c['count']}.inject(0) { |k, v| k + v } - counts_by_operator_flagged.map{|c| c['count']}.inject(0) { |k, v| k + v }) *
            1.0 /
            (counts_by_operator_reviewed.map{|c| c['count']}.inject(0) { |k, v| k + v } - counts_by_operator_reviewed_flagged.map{|c| c['count']}.inject(0) { |k, v| k + v })
        )
    ) / counts_by_operator.map{|c| c['count']}.inject(0) { |k, v| k + v }

    operators_data = Operator.where(enabled: true).where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_3]).sort_by(&:level).map { |operator|
      actions_count = counts_by_operator.find{|c| c['operator_id'] == operator.id}.try(:[], 'count')
      errors_count = counts_by_operator_errors.find{|c| c['operator_id'] == operator.id}.try(:[], 'count')
      reviewed_count = counts_by_operator_reviewed.find{|c| c['operator_id'] == operator.id}.try(:[], 'count')

      actions_flagged_count = counts_by_operator_flagged.find{|c| c['operator_id'] == operator.id}.try(:[], 'count')
      errors_flagged_count = counts_by_operator_errors_flagged.find{|c| c['operator_id'] == operator.id}.try(:[], 'count')
      reviewed_flagged_count = counts_by_operator_reviewed_flagged.find{|c| c['operator_id'] == operator.id}.try(:[], 'count')
      begin
        error_rate = (
            ( errors_flagged_count * actions_flagged_count * 1.0 / reviewed_flagged_count ) +
            ( (errors_count - errors_flagged_count) * (actions_count - actions_flagged_count) * 1.0 / (reviewed_count - reviewed_flagged_count) )
        ) / actions_count
      rescue
        error_rate = 0
      end

      total_duration_in_seconds = operator.operator_presences.where('date >= ? AND is_review = ?', reference_date_month, false).count * 30 * 60 # Each presence is equivalent to 30 minutes so we multiply the count by 30 then by 60 to have it in seconds


      {
          id: operator.id,
          name: operator.name,
          level: operator.level_string,
          actions_count: actions_count,
          coverage: (counts_by_operator_reviewed.find{|c| c['operator_id'] == operator.id}.try(:[], 'count') || 0) * 1.0 / (actions_count || 1),
          errors_percentage: error_rate,
          errors_count: errors_count || 0,
          total_duration_in_seconds: total_duration_in_seconds,
          mails_treatment_hourly_flow: (actions_count || 0) / (total_duration_in_seconds.to_f / 3600)
      }
    }

    if params['sort'].present?
      operators_data = sort_operators_data(params['sort'], operators_data)
    end

    @data = {
        random_review_current_month_count: random_review_current_month_count,
        random_review_current_month_percent: random_actions_current_month_count == 0 ? nil : random_review_current_month_count*100.0/random_actions_current_month_count,

        random_review_last_30_days_count: random_review_last_30_days_count,
        random_review_last_30_days_percent: random_actions_last_30_days_count == 0 ? nil : random_review_last_30_days_count*100.0/random_actions_last_30_days_count,

        random_review_last_7_days_count: random_review_last_7_days_count,
        random_review_last_7_days_percent: random_actions_last_7_days_count == 0 ? nil : random_review_last_7_days_count*100.0/random_actions_last_7_days_count,

        flagged_review_current_month_count: flagged_review_current_month_count,
        flagged_review_last_30_days_count: flagged_review_last_30_days_count,
        flagged_review_last_7_days_count: flagged_review_last_7_days_count,


        flag_to_review_count: flag_count,
        to_group_review_count: OperatorActionsGroup.where(group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).count,
        total_count: total_count_month,
        total_duration_for_all_operators_in_seconds: operators_data.inject(0) {|sum, oa| sum + oa[:total_duration_in_seconds]},
        total_percentage_coverage_for_all_operators: counts_by_operator_reviewed.inject(0) {|sum, oa| sum + oa.count}.to_f / total_count_month,
        total_errors_count_for_all_operators: total_errors_count_for_all_operators,
        total_errors_percentage_for_all_operators: errors_percentage_global,
        operators: operators_data
    }

    if random_actions_last_7_days_percent && random_review_last_7_days_count > 0 && flagged_actions_last_7_days_percent && flagged_review_last_7_days_count > 0
      @data[:last_7_days_error_percent] = (random_error_last_7_days_count*1.0 / random_review_last_7_days_count)*random_actions_last_7_days_percent + (flagged_error_last_7_days_count*1.0 / flagged_review_last_7_days_count)*flagged_actions_last_7_days_percent
    end

    if random_actions_last_30_days_percent && random_review_last_30_days_count > 0 && flagged_actions_last_30_days_percent && flagged_review_last_30_days_count > 0
      @data[:last_30_days_error_percent] = (random_error_last_30_days_count*1.0 / random_review_last_30_days_count)*random_actions_last_30_days_percent + (flagged_error_last_30_days_count*1.0 / flagged_review_last_30_days_count)*flagged_actions_last_30_days_percent
    end

    if random_actions_current_month_percent && random_review_current_month_count > 0 && flagged_actions_current_month_percent && flagged_review_current_month_count > 0
      @data[:current_month_error_percent] = (random_error_current_month_count*1.0 / random_review_current_month_count)*random_actions_current_month_percent + (flagged_error_current_month_count*1.0 / flagged_review_current_month_count)*flagged_actions_current_month_percent
    end
  end

  def messages_thread_ids_to_review
    operator_actions = OperatorActionsGroup.where("initiated_at > ?", DateTime.now - 30.days).where(review_status: nil)



    if params[:mode] == "flag"
      result = EmailServer.search_messages({
                                               after: (DateTime.now - 30.days).to_s,
                                               labels: "flag",
                                               limit: 1000
                                           })

      flag_server_message_ids = result['messages']['ids']
      flag_messages_thread_ids = Message.where(server_message_id: flag_server_message_ids).select(:messages_thread_id).map(&:messages_thread_id).uniq

      if params[:selectivity].present?
        if params[:selectivity] == "even"
          flag_messages_thread_ids = flag_messages_thread_ids.select{|mt_id| mt_id.even?}
        elsif params[:selectivity] == "odd"
          flag_messages_thread_ids = flag_messages_thread_ids.select{|mt_id| mt_id.odd?}
        end
      end

      operator_actions = operator_actions.where(messages_thread_id: flag_messages_thread_ids)
    elsif params[:mode] == "operator"
      operator_actions = operator_actions.where(operator_id: params[:operator_id])
    elsif params[:mode] == "random"
      if params[:selectivity].present?
        if params[:selectivity] == "even"
          operator_actions = operator_actions.where('(messages_thread_id % 2) <> 0')
        elsif params[:selectivity] == "odd"
          operator_actions = operator_actions.where('(messages_thread_id % 2) = 0')
        end
      end
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
