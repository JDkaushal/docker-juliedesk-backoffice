class MessageClassification < ActiveRecord::Base

  belongs_to :message
  has_many :operator_actions, as: :target

  has_one :julie_action

  ASK_DATE_SUGGESTIONS     = "ask_date_suggestions"
  ASK_AVAILABILITIES       = "ask_availabilities"
  ASK_CANCEL_APPOINTMENT   = "ask_cancel_appointment"
  ASK_POSTPONE_APPOINTMENT = "ask_postpone_appointment"
  ASK_INFO                 = "ask_info"
  GIVE_INFO                = "give_info"
  ASK_CREATE_EVENT         = "ask_create_event"
  ASK_CANCEL_EVENTS        = "ask_cancel_events"
  ASK_POSTPONE_EVENTS      = "ask_postpone_events"
  UNKNOWN                  = "unknown"
  FORWARD_TO_SUPPORT       = "forward_to_support"
  INVITATION_ALREADY_SENT  = "invitation_already_sent"

  TO_FOUNDERS              = "to_founders"
  CANCEL_TO_FOUNDERS       = "cancel_to_founders"
  CANCEL_TO_SUPPORT        = "cancel_to_support"


  GIVE_PREFERENCE          = "give_preference"
  ASSOCIATE_EVENT          = "associate_event"
  FORWARD_TO_CLIENT        = "forward_to_client"
  WAIT_FOR_CONTACT         = "wait_for_contact"

  FOLLOWUP_ON_WEEKLY_RECAP = "follow_up_on_weekly_recap"

  NOTHING_TO_DO            = "nothing_to_do"


  REVIEW_STATUS_TO_REVIEW  = nil
  REVIEW_STATUS_TO_LEARN   = 'to_learn'
  REVIEW_STATUS_REVIEWED   = 'reviewed'
  REVIEW_STATUS_LEARNT     = 'learnt'


  THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT   = "scheduling_waiting_for_client"
  THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT  = "scheduling_waiting_for_contact"
  THREAD_STATUS_SCHEDULED                       = "scheduled"
  THREAD_STATUS_SCHEDULING_ABORTED              = "scheduling_aborted"
  THREAD_STATUS_DOES_NOT_CONCERN_CLIENT         = "does_not_concern_client"
  THREAD_STATUS_HANDLED_IN_OTHER_THREADS        = "handled_in_other_threads"
  THREAD_STATUS_EVENTS_CREATION                 = "events_creation"
  THREAD_STATUS_OTHER                           = "other"

  def clean_delete
    if self.julie_action
      OperatorAction.delete_all(target_type: JulieAction.to_s, target_id: self.julie_action.id)
      OperatorActionsGroup.delete_all(target_type: JulieAction.to_s, target_id: self.julie_action.id)
      self.julie_action.delete
    end

    OperatorAction.delete_all(target_type: MessageClassification.to_s, target_id: self.id)
    OperatorActionsGroup.delete_all(target_type: MessageClassification.to_s, target_id: self.id)
    self.delete
  end

  def self.create_from_params params
    attendees = []
    (params[:attendees] || {}).each do |k, att|
      attendees << att
    end
    attendees = MessageClassification.clean_and_categorize_clients attendees

    follow_up_data = nil
    if params[:follow_up_data]
      follow_up_data = params[:follow_up_data].values.to_json
    end

    result = self.new(
        locale: params[:locale],
        timezone: params[:timezone],
        classification: params[:classification],
        appointment_nature: params[:appointment_nature],
        summary: params[:summary],
        duration: params[:duration],
        location_nature: params[:location_nature],
        location: params[:location],
        call_instructions: (params[:call_instructions].blank?)?({}.to_json):(params[:call_instructions].to_json),
        attendees: attendees.to_json,
        notes: params[:notes],
        other_notes: params[:other_notes],
        private: params[:private],
        constraints: params[:constraints],
        constraints_data: (params[:constraints_data].try(:values) || []).to_json,
        client_agreement: params[:client_agreement],
        attendees_are_noticed: params[:attendees_are_noticed],
        number_to_call: params[:number_to_call],
        operator: params[:operator],
        processed_in: params[:processed_in],

        date_times: (params[:date_times].try(:values) || []).to_json,
        thread_status: params[:thread_status],
        follow_up_data: follow_up_data,
        title_preference: params[:title_preference]
    )
    result.save!

    result.append_julie_action

    result
  end

  def self.clean_and_categorize_clients attendees
    accounts = Account.get_active_account_emails(detailed: true)
    attendees.map do |attendee|
      attendee_email = attendee['email']
      if attendee_email.present?
        accounts.select do |account|
          all_emails = [account['email']] + account['email_aliases']
          if all_emails.include?(attendee_email)
            attendee['account_email'] = account['email']
            attendee['usage_name'] = account['usage_name']
          end
        end
        attendee['email'] = attendee_email.gsub(" ", "")
      end
      attendee
    end
  end

  def review_status_as_text
    review_status || "To review"
  end

  def append_julie_action
    if    self.classification == MessageClassification::ASK_DATE_SUGGESTIONS
      create_julie_action action_nature: JulieAction::JD_ACTION_SUGGEST_DATES

    elsif self.classification == MessageClassification::ASK_AVAILABILITIES
      create_julie_action action_nature: JulieAction::JD_ACTION_CHECK_AVAILABILITIES

    elsif self.classification == MessageClassification::ASK_INFO
      create_julie_action action_nature: JulieAction::JD_ACTION_SEND_INFO

    elsif self.classification == MessageClassification::GIVE_INFO
      create_julie_action action_nature: JulieAction::JD_ACTION_SEND_CONFIRMATION

    elsif self.classification == MessageClassification::GIVE_PREFERENCE
      create_julie_action action_nature: JulieAction::JD_ACTION_SEND_CONFIRMATION

    elsif self.classification == MessageClassification::ASK_CANCEL_APPOINTMENT
      create_julie_action action_nature: JulieAction::JD_ACTION_CANCEL_EVENT

    elsif self.classification == MessageClassification::ASK_POSTPONE_APPOINTMENT
      create_julie_action action_nature: JulieAction::JD_ACTION_POSTPONE_EVENT

    elsif self.classification == MessageClassification::ASK_CANCEL_EVENTS
      create_julie_action action_nature: JulieAction::JD_ACTION_CANCEL_MULTIPLE_EVENTS

    elsif self.classification == MessageClassification::ASSOCIATE_EVENT
      create_julie_action action_nature: JulieAction::JD_ACTION_ASSOCIATE_EVENT

    elsif self.classification == MessageClassification::ASK_POSTPONE_EVENTS
      create_julie_action action_nature: JulieAction::JD_ACTION_POSTPONE_MULTIPLE_EVENTS

    elsif self.classification == MessageClassification::ASK_CREATE_EVENT
      create_julie_action action_nature: JulieAction::JD_ACTION_CREATE_EVENT

    elsif self.classification == MessageClassification::UNKNOWN
      create_julie_action action_nature: JulieAction::JD_ACTION_FREE_ACTION
    elsif self.classification == MessageClassification::FORWARD_TO_SUPPORT
      create_julie_action action_nature: JulieAction::JD_ACTION_FORWARD_TO_SUPPORT

    elsif self.classification == MessageClassification::NOTHING_TO_DO
      create_julie_action action_nature: JulieAction::JD_ACTION_NOTHING_TO_DO
    elsif self.classification == MessageClassification::FORWARD_TO_CLIENT
      create_julie_action action_nature: JulieAction::JD_ACTION_FORWARD_TO_CLIENT
    elsif self.classification == MessageClassification::WAIT_FOR_CONTACT
      create_julie_action action_nature: JulieAction::JD_ACTION_WAIT_FOR_CONTACT
    elsif self.classification == MessageClassification::FOLLOWUP_ON_WEEKLY_RECAP
      create_julie_action action_nature: JulieAction::JD_ACTION_FOLLOWUP_ON_WEEKLY_RECAP
    elsif self.classification == MessageClassification::INVITATION_ALREADY_SENT
      create_julie_action action_nature: JulieAction::JD_ACTION_INVITATION_ALREADY_SENT
    end
  end

  def has_data?
    [
        ASK_DATE_SUGGESTIONS,
        ASK_AVAILABILITIES,
        GIVE_INFO,
        ASK_CANCEL_APPOINTMENT,
        ASK_CANCEL_EVENTS,
        ASK_POSTPONE_EVENTS,
        WAIT_FOR_CONTACT,
        INVITATION_ALREADY_SENT
    ].include? classification
  end

  def self.compare message_classifications
    message_classifications.map(&:classification).uniq.length == 1
  end

  def self.is_disabled(message, classification)
    forbidden_classifications = []
    if message.messages_thread.event_data[:event_id]
      forbidden_classifications += [ASK_CANCEL_EVENTS, ASK_POSTPONE_EVENTS]
    else
      forbidden_classifications += [ASK_CANCEL_APPOINTMENT, ASK_POSTPONE_APPOINTMENT]
    end
    forbidden_classifications.include? classification
  end

  def self.all_thread_statuses
    [
        THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT,
        THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT,
        THREAD_STATUS_SCHEDULED,
        THREAD_STATUS_SCHEDULING_ABORTED,
        THREAD_STATUS_HANDLED_IN_OTHER_THREADS,
        THREAD_STATUS_DOES_NOT_CONCERN_CLIENT,
        THREAD_STATUS_EVENTS_CREATION,
        THREAD_STATUS_OTHER
    ]
  end

  def computed_thread_status
    if self.classification == NOTHING_TO_DO
      self.thread_status
    elsif self.classification == UNKNOWN
      self.thread_status
    elsif self.classification == FORWARD_TO_SUPPORT
      self.thread_status
    elsif self.classification == ASK_DATE_SUGGESTIONS
      if self.client_agreement
        THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT
      else
        THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT
      end
    elsif self.classification == ASK_AVAILABILITIES
      if self.julie_action.event_id
        THREAD_STATUS_SCHEDULED
      else
        if self.client_agreement
          THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT
        else
          THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT
        end
      end
    elsif self.classification == ASK_CANCEL_APPOINTMENT
      THREAD_STATUS_SCHEDULING_ABORTED
    elsif self.classification == ASK_POSTPONE_APPOINTMENT
      THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT
    elsif self.classification == ASK_INFO
      nil
    elsif self.classification == GIVE_INFO
      nil
    elsif self.classification == ASK_CREATE_EVENT
      THREAD_STATUS_EVENTS_CREATION
    elsif self.classification == ASK_CANCEL_EVENTS
      THREAD_STATUS_HANDLED_IN_OTHER_THREADS
    elsif self.classification == ASK_POSTPONE_EVENTS
      THREAD_STATUS_HANDLED_IN_OTHER_THREADS
    elsif self.classification == FOLLOWUP_ON_WEEKLY_RECAP
      THREAD_STATUS_HANDLED_IN_OTHER_THREADS
    elsif self.classification == CANCEL_TO_FOUNDERS
      nil
    elsif self.classification == GIVE_PREFERENCE
      nil
    elsif self.classification == FORWARD_TO_CLIENT
      nil
    elsif self.classification == WAIT_FOR_CONTACT
      THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT
    end
  end

  def thread_status_suggestion current_thread_status

  end
end
