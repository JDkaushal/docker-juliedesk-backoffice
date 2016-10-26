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
    operator_actions = OperatorAction.where(messages_thread_id: params[:messages_thread_id], operator_id: params[:operator_id], nature: [OperatorAction::NATURE_ARCHIVE, OperatorAction::NATURE_OPEN, OperatorAction::NATURE_SEND_TO_SUPPORT])

    return nil if operator_actions.empty?
    operator_actions_sorted = operator_actions.sort_by(&:initiated_at)

    # Find last operators which was already grouped
    last_grouped_operator_action = operator_actions_sorted.reverse.find(&:is_grouped?)

    # Starts after the last grouped operator action
    if last_grouped_operator_action
      start_time = last_grouped_operator_action.initiated_at
    else
      start_time = operator_actions_sorted.first.initiated_at - 1.minute
    end

    # Find the first 'open thread' operator action which was not followed by another 'open thread'
    open_thread_oa = operator_actions_sorted.find{|oa| oa.initiated_at > start_time && oa.is_open_thread?}
    return nil if open_thread_oa.nil?
    open_thread_oa_initiated_at = open_thread_oa.initiated_at

    next_operator_actions = operator_actions_sorted.select{|oa| oa.initiated_at > open_thread_oa_initiated_at}

    i = 0
    while i < next_operator_actions.length && next_operator_actions[i].is_open_thread?
      open_thread_oa = next_operator_actions[i]
      i += 1
    end
    open_thread_oa_initiated_at = open_thread_oa.initiated_at


    # Find the following 'archive thread' operator_action
    archive_thread_oa = operator_actions_sorted.find { |oa|
      oa.initiated_at > open_thread_oa_initiated_at &&
          (oa.is_archive_thread? || oa.is_send_to_support?)
    }

    # If found, creates corresponding group
    if archive_thread_oa
      to_group_operator_actions = [open_thread_oa, archive_thread_oa] + operator_actions_sorted.select { |oa|
        oa.initiated_at > open_thread_oa_initiated_at &&
            oa.initiated_at < archive_thread_oa.initiated_at
      }

      target_type = archive_thread_oa.target_type
      target_id   = archive_thread_oa.target_id
      label       = (archive_thread_oa.is_archive_thread?)?(LABEL_ARCHIVE):(LABEL_SEND_TO_SUPPORT)
      if label == LABEL_ARCHIVE
        if (open_julie_action_oa = to_group_operator_actions.find(&:is_open_julie_action?))
          label       = open_julie_action_oa.target.message_classification.classification
          target_type = open_julie_action_oa.target_type
          target_id   = open_julie_action_oa.target_id
        end
      end

      operator_actions_group = OperatorActionsGroup.create({
          operator_id: params[:operator_id],
          messages_thread_id: params[:messages_thread_id],
          label: label,
          target_id: target_id,
          target_type: target_type,
          initiated_at: open_thread_oa_initiated_at,
          finished_at: archive_thread_oa.initiated_at,
          duration: archive_thread_oa.initiated_at - open_thread_oa_initiated_at
                                                           })

      OperatorAction.where(id: to_group_operator_actions.map(&:id)).update_all(operator_actions_group_id: operator_actions_group.id)

      operator_actions_group
    else
      nil
    end

  end

  def is_action?
    label != LABEL_ARCHIVE && label != LABEL_SEND_TO_SUPPORT
  end

  def label_to_display
    if label == LABEL_SEND_TO_SUPPORT
      if self.operator_actions.map(&:message).join.include? "#FollowUp"
        "Follow-up"
      else
        label
      end
    else
      label
    end
  end
end