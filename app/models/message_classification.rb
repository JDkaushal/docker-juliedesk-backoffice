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
  ASK_AND_GIVE_NOTHING     = "ask_and_give_nothing"
  UNKNOWN                  = "unknown"

  def self.create_from_params params
    result = self.new(
        locale: params[:locale],
        timezone: params[:timezone],
        classification: params[:classification],
        appointment_nature: params[:appointment_nature],
        summary: params[:summary],
        duration: params[:duration],
        location: params[:location],
        attendees: (params[:attendees] || []).to_json,
        notes: params[:notes],
        constraints: params[:constraints],

        date_times: (params[:date_times].try(:values) || []).to_json
    )
    result.save!

    result.append_julie_action

    result
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

  def self.compare message_classifications
    message_classifications.map(&:classification).uniq.length == 1
  end


  def self.is_disabled(classification)
    [ASK_CANCEL_APPOINTMENT, ASK_POSTPONE_APPOINTMENT, GIVE_INFO, ASK_CREATE_EVENT].include? classification
  end

  private

  def self.classifications
    {
        primary: [ASK_DATE_SUGGESTIONS, ASK_AVAILABILITIES, ASK_CANCEL_APPOINTMENT, ASK_POSTPONE_APPOINTMENT],
        secondary: [ASK_INFO, GIVE_INFO, ASK_CREATE_EVENT, UNKNOWN]
    }
  end
end
