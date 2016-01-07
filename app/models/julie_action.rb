class JulieAction < ActiveRecord::Base

  belongs_to :message_classification
  has_many :operator_actions, as: :target

  JD_ACTION_CREATE_EVENT             = "create_event"
  JD_ACTION_UPDATE_EVENT             = "update_event"
  JD_ACTION_CANCEL_EVENT             = "cancel_event"
  JD_ACTION_POSTPONE_EVENT           = "postpone_event"
  JD_ACTION_DELETE_EVENT             = "delete_event"
  JD_ACTION_SUGGEST_DATES            = "suggest_dates"
  JD_ACTION_CHECK_AVAILABILITIES     = "check_availabilities"
  JD_ACTION_QUESTION_CLIENT          = "question_client"
  JD_ACTION_SEND_INFO                = "send_info"
  JD_ACTION_SEND_CONFIRMATION        = "send_confirmation"
  JD_ACTION_SEND_TO_FOUNDERS         = "send_to_founders"
  JD_ACTION_CANCEL_MULTIPLE_EVENTS   = "cancel_multiple_events"
  JD_ACTION_POSTPONE_MULTIPLE_EVENTS = "postpone_multiple_events"
  JD_ACTION_FREE_ACTION              = "free_action"
  JD_ACTION_ASSOCIATE_EVENT          = "associate_event"
  JD_ACTION_NOTHING_TO_DO            = "nothing_to_do"
  JD_ACTION_FORWARD_TO_CLIENT        = "forward_to_client"
  JD_ACTION_WAIT_FOR_CONTACT         = "wait_for_contact"
  JD_ACTION_FOLLOWUP_ON_WEEKLY_RECAP = "follow_up_on_weekly_recap"


  def event_data
    message.messages_thread.event_data
  end

  def account
    message.messages_thread.account
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