class OperatorAction < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :messages_thread
  belongs_to :operator
  belongs_to :operator_actions_group

  NATURE_ARCHIVE = "archive"
  NATURE_OPEN    = "open"
  NATURE_LOCK    = "lock"
  NATURE_UNLOCK  = "unlock"

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
        operator_id: params[:operator_id],
        messages_thread_id: params[:messages_thread_id]
    })
    if params[:nature] == NATURE_ARCHIVE
      OperatorActionsGroup.group_actions({
                                             messages_thread_id: params[:messages_thread_id],
                                             operator_id: params[:operator_id]
                                         })
    end
    operator_action
  end
end