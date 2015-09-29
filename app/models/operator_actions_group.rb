class OperatorActionsGroup < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :messages_thread
  belongs_to :operator

  has_many :operator_actions

  LABEL_ARCHIVE                 = "archive"
  LABEL_SEND_TO_SUPPORT         = "send_to_support"
  REVIEW_STATUS_TO_REVIEW       = nil
  REVIEW_STATUS_TO_LEARN        = "to_learn"
  REVIEW_STATUS_LEARNT          = "learnt"
  REVIEW_STATUS_REVIEWED        = "reviewed"

  GROUP_REVIEW_STATUS_TO_LEARN  = "to_learn"
  GROUP_REVIEW_STATUS_LEARNT    = "learnt"
  GROUP_REVIEW_STATUS_UNSET     = nil

  def self.group_actions params
    # Find all operator actions for this thread and operator
    operator_actions = OperatorAction.where(messages_thread_id: params[:messages_thread_id], operator_id: params[:operator_id])

    # Find last operators which was already grouped
    operator_actions = operator_actions.select(&:real_action?)
    last_grouped_operator_action = operator_actions.select(&:is_grouped?).sort_by(&:initiated_at).last

    return nil if operator_actions.empty?

    # Starts after the last grouped operator action
    if last_grouped_operator_action
      start_time = last_grouped_operator_action.initiated_at
    else
      start_time = operator_actions.map(&:initiated_at).min - 1.minute
    end


    # Find the first 'open thread' operator action which was not followed by another 'open thread'
    open_thread_oa = operator_actions.sort_by(&:initiated_at).select{|oa| oa.initiated_at > start_time && oa.is_open_thread?}.first
    return nil if open_thread_oa.nil?

    next_operator_actions = operator_actions.sort_by(&:initiated_at).select{|oa| oa.initiated_at > open_thread_oa.initiated_at}
    i = 0
    while i < next_operator_actions.length && next_operator_actions[i].is_open_thread?
      open_thread_oa = next_operator_actions[i]
      i += 1
    end

    # Find the following 'archive thread' operator_action
    archive_thread_oa = operator_actions.sort_by(&:initiated_at).select { |oa|
      oa.initiated_at > open_thread_oa.initiated_at &&
          (oa.is_archive_thread? || oa.is_send_to_support?)
    }.first

    # If found, creates corresponding group
    if archive_thread_oa
      to_group_operator_actions = [open_thread_oa, archive_thread_oa] + operator_actions.sort_by(&:initiated_at).select { |oa|
        oa.initiated_at > open_thread_oa.initiated_at &&
            oa.initiated_at < archive_thread_oa.initiated_at
      }

      target_type = archive_thread_oa.target_type
      target_id   = archive_thread_oa.target_id
      label       = (archive_thread_oa.is_archive_thread?)?(LABEL_ARCHIVE):(LABEL_SEND_TO_SUPPORT)
      if (open_julie_action_oa = to_group_operator_actions.select(&:is_open_julie_action?).first)
        label       = open_julie_action_oa.target.message_classification.classification
        target_type = open_julie_action_oa.target_type
        target_id   = open_julie_action_oa.target_id
      end

      operator_actions_group = OperatorActionsGroup.create({
          operator_id: params[:operator_id],
          messages_thread_id: params[:messages_thread_id],
          label: label,
          target_id: target_id,
          target_type: target_type,
          initiated_at: open_thread_oa.initiated_at,
          duration: archive_thread_oa.initiated_at - open_thread_oa.initiated_at

                                                           })
      to_group_operator_actions.each do |operator_action|
        operator_action.update_attribute :operator_actions_group_id, operator_actions_group.id
      end

      operator_actions_group
    else
      nil
    end

  end

  def is_action?
    label != LABEL_ARCHIVE && label != LABEL_SEND_TO_SUPPORT
  end
end