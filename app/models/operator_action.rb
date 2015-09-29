class OperatorAction < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :messages_thread
  belongs_to :operator
  belongs_to :operator_actions_group

  NATURE_ARCHIVE = "archive"
  NATURE_OPEN    = "open"
  NATURE_LOCK    = "lock"
  NATURE_UNLOCK  = "unlock"
  NATURE_SEND_TO_SUPPORT = "send_to_support"

  SUB_NATURE_NOTHING_EXPECTED   = "nothing_expected_from_me"
  SUB_NATURE_WAITING_FOR_REPLY  = "waiting_for_reply"

  def real_action?
    ![NATURE_LOCK, NATURE_UNLOCK].include? nature
  end

  def target_using_cache
    if is_open_message_classification?
      self.messages_thread.messages.map(&:message_classifications).flatten.select{|mc| mc.id == self.target_id}.first
    elsif is_open_julie_action?
      self.messages_thread.messages.map(&:message_classifications).flatten.map(&:julie_action).select{|ja| ja.id == self.target_id}.first
    else
      target
    end
  end

  def is_open_thread?
    self.target_type == MessagesThread.to_s &&
        self.nature == NATURE_OPEN
  end

  def is_archive_thread?
    self.target_type == MessagesThread.to_s &&
        self.nature == NATURE_ARCHIVE
  end

  def is_send_to_support?
    self.target_type == MessagesThread.to_s &&
        self.nature == NATURE_SEND_TO_SUPPORT
  end

  def is_open_julie_action?
    self.target_type == JulieAction.to_s
  end

  def is_open_message_classification?
    self.target_type == MessageClassification.to_s
  end

  def is_grouped?
    self.operator_actions_group_id.present?
  end

  def self.create_and_verify params
    raise "No target specified" unless params[:target]
    operator_action = params[:target].operator_actions.create({
        initiated_at: params[:initiated_at],
        nature: params[:nature],
        sub_nature: params[:sub_nature],
        operator_id: params[:operator_id],
        messages_thread_id: params[:messages_thread_id],
        message: params[:message]
    })
    if params[:nature] == NATURE_ARCHIVE || params[:nature] == NATURE_SEND_TO_SUPPORT
      OperatorActionsGroup.group_actions({
                                             messages_thread_id: params[:messages_thread_id],
                                             operator_id: params[:operator_id]
                                         })
    end
    operator_action
  end

  def nature_description params={}
    result = if self.is_open_julie_action?
      "Open JulieAction"
    elsif self.is_open_message_classification?
      "Open MessageClassification"
    elsif self.is_archive_thread?
      "Archive thread"
    elsif self.is_open_thread?
      "Open thread"
    elsif self.is_send_to_support?
      "Send to support"
    elsif self.nature == NATURE_LOCK
      "Lock thread"
    elsif self.nature == NATURE_UNLOCK
      "Unlock thread"
    else
       "Unknown"
    end

    if params[:with_id]
      "#{result} ##{self.target_id}"
    else
      result
    end

  end
end