class JulieAction < ActiveRecord::Base

  belongs_to :message_classification
  has_many :operator_actions, as: :target
  has_one :date_suggestions_comparison_review

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
  JD_ACTION_FORWARD_TO_SUPPORT       = "forward_to_support"

  JD_ACTION_ASSOCIATE_EVENT          = "associate_event"
  JD_ACTION_NOTHING_TO_DO            = "nothing_to_do"
  JD_ACTION_FORWARD_TO_CLIENT        = "forward_to_client"
  JD_ACTION_WAIT_FOR_CONTACT         = "wait_for_contact"
  JD_ACTION_FOLLOWUP_ON_WEEKLY_RECAP = "follow_up_on_weekly_recap"
  JD_ACTION_INVITATION_ALREADY_SENT  = "invitation_already_sent"

  JD_ACTION_FOLLOW_UP_CLIENT         = "follow_up_client"
  JD_ACTION_FOLLOW_UP_CONTACTS       = "follow_up_contacts"

  # Allow to delete avery event related informations from the julie action (used mostly to de-associate an event from a Thread)
  def clear_event_data
    self.update(event_id: nil, calendar_login_username: nil, calendar_id: nil)
  end

  def self.available_actions

    [
      JulieAction::JD_ACTION_SUGGEST_DATES,
      JulieAction::JD_ACTION_CHECK_AVAILABILITIES,
      JulieAction::JD_ACTION_SEND_INFO,
      JulieAction::JD_ACTION_SEND_CONFIRMATION,
      JulieAction::JD_ACTION_FREE_ACTION,
      JulieAction::JD_ACTION_CANCEL_EVENT,
      JulieAction::JD_ACTION_CREATE_EVENT,
      JulieAction::JD_ACTION_CANCEL_MULTIPLE_EVENTS,
      JulieAction::JD_ACTION_POSTPONE_MULTIPLE_EVENTS,
      JulieAction::JD_ACTION_FORWARD_TO_CLIENT,
      JulieAction::JD_ACTION_FORWARD_TO_SUPPORT,
      JulieAction::JD_ACTION_WAIT_FOR_CONTACT,
      JulieAction::JD_ACTION_FOLLOWUP_ON_WEEKLY_RECAP,
      JulieAction::JD_ACTION_INVITATION_ALREADY_SENT,
      JulieAction::JD_ACTION_FOLLOW_UP_CLIENT,
      JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS
    ].freeze

  end

  def get_messages_thread_reminder_date
    case self.action_nature
      when JulieAction::JD_ACTION_SUGGEST_DATES
        get_suggested_dates_barycentre
      when JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS
        get_suggested_dates_barycentre
      when JulieAction::JD_ACTION_CHECK_AVAILABILITIES
        get_suggested_dates_barycentre
      when JulieAction::JD_ACTION_WAIT_FOR_CONTACT
        Time.now + 3.days
      when JulieAction::JD_ACTION_FREE_ACTION
        Time.now + 3.days
      else
        nil
    end
  end

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

  private

  def get_suggested_dates_barycentre
    # When there are no date_times proposed, it means it was an event creation
    # So we will not set a reminder
    if self.date_times == "[]"
      self.action_nature == JulieAction::JD_ACTION_CHECK_AVAILABILITIES ? nil : Time.now + 3.days
    else
      parsed_dates = JSON.parse(self.date_times).map{|d| d['date']}
      barycentre = DateTime.parse(parsed_dates.shift)
      now = Time.now

      parsed_dates.push(now.to_s)

      if parsed_dates.size > 0
        parsed_dates.each do |date|
          date = DateTime.parse(date)
          barycentre = barycentre + (get_hours_diff(barycentre, date) / 2).hours
        end
      end

      #barycentre.change(hour: 10, min: 10)
      barycentre
    end
  end

  def get_days_diff(date1, date2)
    (date2 - date1).to_i
  end

  def get_hours_diff(date1, date2)
    ((date2.to_time - date1.to_time)/1.hour).round
  end
end