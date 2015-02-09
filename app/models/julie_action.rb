class JulieAction < ActiveRecord::Base

  belongs_to :message_classification

  JD_ACTION_CREATE_EVENT            = "create_event"
  JD_ACTION_UPDATE_EVENT            = "update_event"
  JD_ACTION_CANCEL_EVENT            = "cancel_event"
  JD_ACTION_DELETE_EVENT            = "delete_event"
  JD_ACTION_SUGGEST_DATES           = "suggest_dates"
  JD_ACTION_CHECK_AVAILABILITIES    = "check_availabilities"
  JD_ACTION_QUESTION_CLIENT         = "question_client"
  JD_ACTION_SEND_INFO               = "send_info"
  JD_ACTION_SEND_CONFIRMATION       = "send_confirmation"
  JD_ACTION_SEND_TO_FOUNDERS        = "send_to_founders"
  JD_ACTION_FREE_ACTION             = "free_action"



  def self.create_from_message message
    classification = message.message_classifications.last.classification
    if classification == MessageClassification::ASK_DATE_SUGGESTIONS
      message.julie_actions.create action_nature: JD_ACTION_SUGGEST_DATES
    elsif classification == MessageClassification::ASK_AVAILABILITIES
      message.julie_actions.create action_nature: JD_ACTION_CHECK_AVAILABILITIES
    elsif classification == MessageClassification::ASK_INFO
      message.julie_actions.create action_nature: JD_ACTION_SEND_INFO
    elsif classification == MessageClassification::GIVE_INFO
      message.julie_actions.create action_nature: JD_ACTION_SEND_CONFIRMATION
    else classification == MessageClassification::UNKNOWN
      message.julie_actions.create action_nature: JD_ACTION_FREE_ACTION
    end

  end

  def event_data
    message.messages_thread.event_data
  end

  def account
    message.messages_thread.account
  end

  def old_process
    if    self.action_nature == JD_ACTION_CREATE_EVENT
      account.create_event event_data
    elsif self.action_nature == JD_ACTION_UPDATE_EVENT
      account.update_event event_data
    elsif self.action_nature == JD_ACTION_DELETE_EVENT
      account.delete_event event_data
    elsif self.action_nature == JD_ACTION_SEND_SUGGESTIONS_EMAIL
      self.send_suggestions_email event_data
    elsif self.action_nature == JD_ACTION_SEND_QUESTION_TO_CLIENT
      self.send_question_to_client event_data
    elsif self.action_nature == JD_ACTION_SEND_INFO
      self.send_info event_data
    elsif self.action_nature == JD_ACTION_SEND_TO_FOUNDERS
      self.send_to_founders event_data
    end
  end

  def send_suggestions_email event_data

  end

  def send_question_to_client event_data

  end

  def send_info event_data

  end

  def send_to_founders event_data

  end
end