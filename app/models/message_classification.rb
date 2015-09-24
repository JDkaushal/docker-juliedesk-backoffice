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
  TO_FOUNDERS              = "to_founders"
  CANCEL_TO_FOUNDERS       = "cancel_to_founders"
  GIVE_PREFERENCE          = "give_preference"
  ASSOCIATE_EVENT          = "associate_event"


  REVIEW_STATUS_TO_REVIEW  = nil
  REVIEW_STATUS_TO_LEARN   = 'to_learn'
  REVIEW_STATUS_REVIEWED   = 'reviewed'
  REVIEW_STATUS_LEARNT     = 'learnt'

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
    result = self.new(
        locale: params[:locale],
        timezone: params[:timezone],
        classification: params[:classification],
        appointment_nature: params[:appointment_nature],
        summary: params[:summary],
        duration: params[:duration],
        location_nature: params[:location_nature],
        location: params[:location],
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

        date_times: (params[:date_times].try(:values) || []).to_json
    )
    result.save!

    result.append_julie_action

    result
  end

  def self.clean_and_categorize_clients attendees
    accounts = Account.get_active_account_emails(detailed: true)
    attendees.select do |attendee|
      attendee['email']
    end.map do |attendee|
      accounts.select do |account|
        all_emails = [account['email']] + account['email_aliases']
        if all_emails.include? attendee['email']
          attendee['account_email'] = account['email']
          attendee['usage_name'] = account['usage_name']
        end
      end
      attendee['email'] = attendee['email'].gsub(" ", "")

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

    else  self.classification == MessageClassification::UNKNOWN
      create_julie_action action_nature: JulieAction::JD_ACTION_FREE_ACTION

    end
  end

  def self.all_classifications
    self.classifications.values.flatten
  end

  def self.primary_classifications
    self.classifications[:primary]
  end

  def self.secondary_classifications
    self.classifications[:secondary]
  end

  def self.no_account_classifications
    return [UNKNOWN]
  end

  def has_data?
    [
        ASK_DATE_SUGGESTIONS,
        ASK_AVAILABILITIES,
        GIVE_INFO,
        ASK_CANCEL_APPOINTMENT,
        ASK_CANCEL_EVENTS,
        ASK_POSTPONE_EVENTS
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



  private

  def self.classifications
    {
        primary: [ASK_DATE_SUGGESTIONS, ASK_AVAILABILITIES, ASK_CANCEL_APPOINTMENT, ASK_POSTPONE_APPOINTMENT],
        secondary: [ASK_INFO, GIVE_INFO, ASK_CREATE_EVENT, ASK_CANCEL_EVENTS, ASK_POSTPONE_EVENTS, UNKNOWN]
    }
  end
end
