class Admin::StatsController < AdminController
  skip_before_action :only_admin, only: [:production, :production_ey, :production_sg]
  before_action :only_admin_or_manager, only: [:production, :production_ey, :production_sg]

  def main
    params[:date] ||= DateTime.now.to_s
    date = DateTime.parse(params[:date])
    @data = {}
    (-3..0).map do |month|
      @data[(date + month.months).strftime("%Y-%m-01")] = ApplicationHelper.messages_and_delay_stats date + month.months, params[:exclude].present?
    end
  end

  def production
    @date = DateTime.now
    @date = DateTime.parse(params[:start]) if params[:start]
    @date = @date.beginning_of_week

    start_date = @date
    end_date = @date + 1.week


    messages = Message.where(from_me: true).where("received_at >= ? AND received_at <= ?", start_date, end_date).where.not(request_at: nil)



    flagged_server_messages_ids = EmailServer.search_messages({
                                                                  after: start_date.to_s,
                                                                  before: end_date.to_s,
                                                                  labels: "flag",
                                                                  limit: 1000
                                                              })['messages']['ids']

    team_operator_ids = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1,Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2,Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_3]).select(:id).map(&:id)

    flagged_messages_thread_ids = Message.where(server_message_id: flagged_server_messages_ids).select(:messages_thread_id).distinct.map(&:messages_thread_id)

    actions_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, end_date).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).count

    reviewed_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).where(operator_id: team_operator_ids, review_notation: [0, 1, 2, 3, 4, 5]).count
    errors_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).where(operator_id: team_operator_ids, review_notation: [0, 1, 2, 3]).count

    flagged_errors_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).where(operator_id: team_operator_ids, review_notation: [0, 1, 2, 3], messages_thread_id: flagged_messages_thread_ids).count
    non_flagged_errors_count = errors_count - flagged_errors_count

    flagged_reviewed_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).where(operator_id: team_operator_ids, review_notation: [0, 1, 2, 3, 4, 5], messages_thread_id: flagged_messages_thread_ids).count
    non_flagged_reviewed_count = reviewed_count - flagged_reviewed_count

    actions_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).where(operator_id: team_operator_ids).count
    flagged_actions_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).where(operator_id: team_operator_ids, messages_thread_id: flagged_messages_thread_ids).count
    non_flagged_actions_count = actions_count - flagged_actions_count

    errors_rate = (
    (flagged_errors_count * flagged_actions_count * 1.0 / flagged_reviewed_count) +
        (non_flagged_errors_count * non_flagged_actions_count * 1.0 / non_flagged_reviewed_count)
    ) / actions_count


    @data = {
        operator_actions_groups_count: actions_count,
        delay_p75: (ApplicationHelper.percentile(messages.map{|m| m.received_at - m.request_at}, 0.75) || 0) / 60.0,
        operator_actions_groups_reviewed_ratio: reviewed_count * 1.0 / actions_count,
        errors_rate: errors_rate
    }
  end
end
