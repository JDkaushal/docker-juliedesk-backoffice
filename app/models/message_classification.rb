class MessageClassification < ActiveRecord::Base

  belongs_to :message

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
  GIVE_PREFERENCE          = "give_preference"
  ASSOCIATE_EVENT          = "associate_event"

  def self.create_from_params params
    attendees = []
    (params[:attendees] || {}).each do |k, att|
      attendees << att
    end
    attendees = MessageClassification.categorize_clients attendees
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
        operator: params[:operator],
        processed_in: params[:processed_in],

        date_times: (params[:date_times].try(:values) || []).to_json
    )
    result.save!

    result.append_julie_action

    result
  end

  def self.categorize_clients attendees
    accounts = Account.get_active_account_emails(detailed: true)
    attendees.each do |attendee|
      accounts.select do |account|
        all_emails = [account['email']] + account['email_aliases']
        if all_emails.include? attendee['email']
          attendee['account_email'] = account['email']
        end
      end
    end

    attendees
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

  def self.test_language_detection
    message_classifications = MessageClassification.where("locale is NOT NULL").includes(:message)

    raw_data = message_classifications.map { |mc|
      text = "#{mc.message.google_message.subject}\n\n#{mc.message.google_message.text}"
      {
          text: text,
          locale: mc.locale,
          detected_locale: DetectLanguage.simple_detect(text)
      }
    }

    conflicts = raw_data.select{|d|
      d[:locale] != d[:detected_locale]
    }

    data = {
        data_count: raw_data.length,
        conflicts_count: conflicts.length,

        raw_data: raw_data,
        conflicts: conflicts
    }
  end

  private

  def self.classifications
    {
        primary: [ASK_DATE_SUGGESTIONS, ASK_AVAILABILITIES, ASK_CANCEL_APPOINTMENT, ASK_POSTPONE_APPOINTMENT],
        secondary: [ASK_INFO, GIVE_INFO, ASK_CREATE_EVENT, ASK_CANCEL_EVENTS, ASK_POSTPONE_EVENTS, UNKNOWN]
    }
  end
end
