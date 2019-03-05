class MessageClassification < ActiveRecord::Base
  include Attendable


  belongs_to :message
  has_many :operator_actions, as: :target

  has_one :julie_action

  attr_accessor :ignore_linked_attendees

  before_validation :clean_client_on_trip

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
  UPDATE_EVENT             = "update_event"
  FOLLOW_UP_CONTACTS       = "follow_up_contacts"
  FOLLOW_UP_CLIENT         = "follow_up_client"
  HANDLED_BY_CLIENT        = "handled_by_client"

  TO_FOUNDERS              = "to_founders"
  CANCEL_TO_FOUNDERS       = "cancel_to_founders"
  CANCEL_TO_SUPPORT        = "cancel_to_support"


  GIVE_PREFERENCE          = "give_preference"
  ASSOCIATE_EVENT          = "associate_event"
  FORWARD_TO_CLIENT        = "forward_to_client"
  WAIT_FOR_CONTACT         = "wait_for_contact"

  FOLLOWUP_ON_WEEKLY_RECAP = "follow_up_on_weekly_recap"

  NOTHING_TO_DO            = "nothing_to_do"

  CLASSIFICATIONS_WITH_DATA = [
      ASK_DATE_SUGGESTIONS,
      ASK_AVAILABILITIES,
      GIVE_INFO,
      ASK_CANCEL_APPOINTMENT,
      ASK_CANCEL_EVENTS,
      ASK_POSTPONE_EVENTS,
      WAIT_FOR_CONTACT,
      UPDATE_EVENT,
      FOLLOW_UP_CONTACTS
  ]

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
  THREAD_STATUS_HANDLED_BY_CLIENT               = "handled_by_client"
  THREAD_STATUS_EVENTS_CREATION                 = "events_creation"
  THREAD_STATUS_OTHER                           = "other"

  SCHEDULING_CLASSIFICATIONS = [
    THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT,
    THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT
  ]

  # Virtual
  APPOINTMENT_TYPE_VIRTUAL  = 'virtual'

  APPOINTMENT_TYPE_CALL     = 'call'
  APPOINTMENT_TYPE_SKYPE    = 'skype'
  APPOINTMENT_TYPE_HANGOUT  = 'hangout'
  APPOINTMENT_TYPE_WEBEX    = 'webex'

  # Physical
  APPOINTMENT_TYPE_PHYSICAL     = 'physical'

  APPOINTMENT_TYPE_APPOINTMENT  = 'appointment'
  APPOINTMENT_TYPE_MEETING      = 'meeting'
  APPOINTMENT_TYPE_LUNCH        = 'lunch'
  APPOINTMENT_TYPE_COFFEE       = 'coffee'
  APPOINTMENT_TYPE_WORK_SESSION = 'work_session'
  APPOINTMENT_TYPE_DINNER       = 'dinner'
  APPOINTMENT_TYPE_BREAKFAST    = 'breakfast'
  APPOINTMENT_TYPE_DRINK        = 'dinner'


  APPOINTMENT_BEHAVIOUR_PROPOSE             = 'propose'
  APPOINTMENT_BEHAVIOUR_ASK_LATER           = 'later'
  APPOINTMENT_BEHAVIOUR_ASK_INTERLOCUTOR    = 'ask_interlocutor'

  # confcall is obsolete ?
  VIRTUAL_EVENT_TYPES = [
      APPOINTMENT_TYPE_CALL,
      APPOINTMENT_TYPE_SKYPE,
      APPOINTMENT_TYPE_HANGOUT,
      APPOINTMENT_TYPE_WEBEX
  ]

  PHYSICAL_EVENT_TYPES = [
      APPOINTMENT_TYPE_APPOINTMENT,
      APPOINTMENT_TYPE_MEETING,
      APPOINTMENT_TYPE_LUNCH,
      APPOINTMENT_TYPE_COFFEE,
      APPOINTMENT_TYPE_WORK_SESSION,
      APPOINTMENT_TYPE_DINNER,
      APPOINTMENT_TYPE_BREAKFAST,
      APPOINTMENT_TYPE_DRINK
  ]



  scope :with_data, -> { where(classification: CLASSIFICATIONS_WITH_DATA) }

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

  def self.create_from_params(params)
    if params[:classification] == MessageClassification::INVITATION_ALREADY_SENT
      message_thread = MessagesThread.find(params[:messages_thread_id])
      last_classification_with_data = message_thread.last_message_classification_with_data || {}

      result = self.new(
          locale: params[:locale],
          timezone: last_classification_with_data.try(:timezone),
          classification: params[:classification],
          appointment_nature: last_classification_with_data.try(:appointment_nature),
          summary: last_classification_with_data.try(:summary),
          duration: last_classification_with_data.try(:duration),
          client_on_trip: last_classification_with_data.try(:client_on_trip),
          location_nature: last_classification_with_data.try(:location_nature),
          location: last_classification_with_data.try(:location),
          location_coordinates: (params[:location_coordinates] || []),

          # call informations
          call_instructions: last_classification_with_data.try(:call_instructions),
          ###
          #
          attendees: last_classification_with_data.try(:attendees),
          notes:last_classification_with_data.try(:notes),
          other_notes: last_classification_with_data.try(:other_notes),
          private: last_classification_with_data.try(:private),
          constraints: last_classification_with_data.try(:constraints),
          constraints_data: last_classification_with_data.try(:constraints_data),
          client_agreement: last_classification_with_data.try(:client_agreement),
          attendees_are_noticed: last_classification_with_data.try(:attendees_are_noticed),

          # call informations
          number_to_call: last_classification_with_data.try(:number_to_call),
          ###
          #
          operator: last_classification_with_data.try(:operator),
          processed_in: last_classification_with_data.try(:processed_in),
          date_times: last_classification_with_data.try(:date_times),
          thread_status: last_classification_with_data.try(:thread_status),
          follow_up_data:last_classification_with_data.try(:follow_up_data),
          title_preference: last_classification_with_data.try(:title_preference),
          using_meeting_room: last_classification_with_data.try(:using_meeting_room),
          meeting_room_details: last_classification_with_data.try(:meeting_room_details),
          booked_rooms_details: last_classification_with_data.try(:booked_rooms_details),
          using_restaurant_booking: last_classification_with_data.try(:using_restaurant_booking),
          restaurant_booking_details: last_classification_with_data.try(:restaurant_booking_details),
          location_changed: last_classification_with_data.try(:location_changed),
          virtual_resource_used: last_classification_with_data.try(:virtual_resource_used),
          before_update_data: params[:before_update_data],
          verified_dates_by_ai: (params[:verified_dates_by_ai] || {}).to_json,
          passed_conditions: (params[:passed_conditions] || {}).to_json,
          language_level: last_classification_with_data.try(:language_level),
          asap_constraint: params[:asap_constraint],
          identifier: params[:message_classification_identifier],
          cluster_specified_location: params[:cluster_specified_location],
          attendees_emails: last_classification_with_data.try(:attendees_emails)
      )
    else
      attendees = params.fetch(:attendees, [])
      attendees = MessageClassification.clean_and_categorize_clients(attendees)

      follow_up_data = nil
      if params[:follow_up_data]
        follow_up_data = params[:follow_up_data].to_json
      end

      sanitized_timezone = params[:timezone].present? ? params[:timezone].strip : nil

      result = self.new(
          locale: params[:locale],
          # Extra protection against trailing whitespace causing bugs with timezones
          timezone: sanitized_timezone,
          classification: params[:classification],
          appointment_nature: params[:appointment_nature],
          summary: params[:summary],
          duration: params[:duration],
          client_on_trip: params[:client_on_trip].blank? ? nil : params[:client_on_trip],
          location_nature: params[:location_nature],
          location: params[:location],
          location_coordinates: (params[:location_coordinates] || []),
          notes: params[:notes],
          other_notes: params[:other_notes],
          private: params[:private],
          constraints: params[:constraints],
          client_agreement: params[:client_agreement],
          attendees_are_noticed: params[:attendees_are_noticed],
          number_to_call: params[:number_to_call],
          operator: params[:operator],
          processed_in: params[:processed_in],
          thread_status: params[:thread_status],
          follow_up_data: follow_up_data,
          title_preference: params[:title_preference],
          using_meeting_room: params[:using_meeting_room] || false,
          using_restaurant_booking: params[:using_restaurant_booking] || false,
          location_changed: params[:location_changed],
          ignore_linked_attendees: params[:ignore_linked_attendees],
          language_level: params[:language_level],
          asap_constraint: params[:asap_constraint],
          identifier: params[:message_classification_identifier],
          cluster_specified_location: params[:cluster_specified_location],
          attendees_emails: self.get_attendees_emails(attendees),

          # properties with JSON column type
          before_update_data: params[:before_update_data],
          verified_dates_by_ai: params.fetch(:verified_dates_by_ai, {}),
          meeting_room_details: params.fetch(:meeting_room_details, {}),
          booked_rooms_details: params.fetch(:booked_rooms_details, {}),
          restaurant_booking_details: params.fetch(:restaurant_booking_details, {}),
          passed_conditions: params.fetch(:passed_conditions, {}),
          virtual_resource_used: params[:virtual_resource_used],

          # properties with TEXT column type (but stored as json)
          attendees: attendees.to_json,
          date_times: (params[:date_times] || []).to_json,
          constraints_data: (params[:constraints_data] || []).to_json,
          call_instructions: (params[:call_instructions].blank? ? {} : params[:call_instructions]).to_json,
      )
    end

    result.save!

    result.append_julie_action

    result
  end

  def parsed_attendees
    JSON.parse(self.attendees || "[]")
  end

  def present_attendees
    parsed_attendees.select{|att| att['isPresent'] == "true"}
  end

  def used_timezones
    if is_virtual_appointment?
      ([self.timezone] + self.present_attendees.map{|att| att['timezone']}).compact.uniq
    else
      [self.timezone]
    end
  end

  def is_virtual_appointment?
    VIRTUAL_EVENT_TYPES.include? self.appointment_nature
  end

  def is_physical_appointment?
    PHYSICAL_EVENT_TYPES.include? self.appointment_nature
  end

  def self.clean_and_categorize_clients attendees
    accounts = Account.get_active_account_emails(detailed: true)
    result = attendees.map do |attendee|
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

    result
  end

  def self.get_attendees_emails(attendees)
    attendees.map{|att| att['accountEmail'] || att['email']}
  end

  def other_account_emails
    JSON.parse(self.attendees || "[]").select do |attendee|
      attendee['isPresent'] == "true" &&
          attendee['isClient'] == "true" &&
          (attendee['accountEmail'] || attendee['account_email']) &&
          attendee['isThreadOwner'] != 'true'
    end.map do |attendee|
      attendee['accountEmail'] ? attendee['accountEmail'] : attendee['account_email']
    end.compact
  end

  def review_status_as_text
    review_status || "To review"
  end

  def computed_julie_action_nature
    julie_action_nature = nil

    case self.classification
      when MessageClassification::ASK_DATE_SUGGESTIONS
        julie_action_nature = self.message && self.message.messages_thread.do_not_ask_suggestions? && !self.ignore_linked_attendees ? JulieAction::JD_ACTION_CHECK_AVAILABILITIES : JulieAction::JD_ACTION_SUGGEST_DATES
      when MessageClassification::ASK_AVAILABILITIES
        julie_action_nature = JulieAction::JD_ACTION_CHECK_AVAILABILITIES
      when MessageClassification::ASK_INFO
        julie_action_nature = JulieAction::JD_ACTION_SEND_INFO
      when MessageClassification::GIVE_INFO
        julie_action_nature = JulieAction::JD_ACTION_SEND_CONFIRMATION
      when MessageClassification::UPDATE_EVENT
        julie_action_nature = JulieAction::JD_ACTION_SEND_CONFIRMATION
      when MessageClassification::GIVE_PREFERENCE
        julie_action_nature = JulieAction::JD_ACTION_SEND_CONFIRMATION
      when MessageClassification::ASK_CANCEL_APPOINTMENT
        julie_action_nature = JulieAction::JD_ACTION_CANCEL_EVENT
      when MessageClassification::ASK_POSTPONE_APPOINTMENT
        julie_action_nature = JulieAction::JD_ACTION_POSTPONE_EVENT
      when MessageClassification::ASK_CANCEL_EVENTS
        julie_action_nature = JulieAction::JD_ACTION_CANCEL_MULTIPLE_EVENTS
      when MessageClassification::ASSOCIATE_EVENT
        julie_action_nature = JulieAction::JD_ACTION_ASSOCIATE_EVENT
      when MessageClassification::ASK_POSTPONE_EVENTS
        julie_action_nature = JulieAction::JD_ACTION_POSTPONE_MULTIPLE_EVENTS
      when MessageClassification::ASK_CREATE_EVENT
        julie_action_nature = JulieAction::JD_ACTION_CREATE_EVENT
      when MessageClassification::UNKNOWN
        julie_action_nature = JulieAction::JD_ACTION_FREE_ACTION
      when MessageClassification::FORWARD_TO_SUPPORT
        julie_action_nature = JulieAction::JD_ACTION_FORWARD_TO_SUPPORT
      when MessageClassification::NOTHING_TO_DO
        julie_action_nature = JulieAction::JD_ACTION_NOTHING_TO_DO
      when MessageClassification::FORWARD_TO_CLIENT
        julie_action_nature = JulieAction::JD_ACTION_FORWARD_TO_CLIENT
      when MessageClassification::WAIT_FOR_CONTACT
        julie_action_nature = JulieAction::JD_ACTION_WAIT_FOR_CONTACT
      when MessageClassification::FOLLOWUP_ON_WEEKLY_RECAP
        julie_action_nature = JulieAction::JD_ACTION_FOLLOWUP_ON_WEEKLY_RECAP
      when MessageClassification::INVITATION_ALREADY_SENT
        julie_action_nature = JulieAction::JD_ACTION_INVITATION_ALREADY_SENT
      when MessageClassification::FOLLOW_UP_CLIENT
        julie_action_nature = JulieAction::JD_ACTION_FOLLOW_UP_CLIENT
      when MessageClassification::FOLLOW_UP_CONTACTS
        julie_action_nature = JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS
    end

    julie_action_nature
  end
  def append_julie_action


    create_julie_action action_nature: computed_julie_action_nature

    # if    self.classification == MessageClassification::ASK_DATE_SUGGESTIONS
    #   create_julie_action action_nature: JulieAction::JD_ACTION_SUGGEST_DATES
    #
    # elsif self.classification == MessageClassification::ASK_AVAILABILITIES
    #   create_julie_action action_nature: JulieAction::JD_ACTION_CHECK_AVAILABILITIES
    #
    # elsif self.classification == MessageClassification::ASK_INFO
    #   create_julie_action action_nature: JulieAction::JD_ACTION_SEND_INFO
    #
    # elsif self.classification == MessageClassification::GIVE_INFO || self.classification == MessageClassification::UPDATE_EVENT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_SEND_CONFIRMATION
    #
    # elsif self.classification == MessageClassification::GIVE_PREFERENCE
    #   create_julie_action action_nature: JulieAction::JD_ACTION_SEND_CONFIRMATION
    #
    # elsif self.classification == MessageClassification::ASK_CANCEL_APPOINTMENT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_CANCEL_EVENT
    #
    # elsif self.classification == MessageClassification::ASK_POSTPONE_APPOINTMENT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_POSTPONE_EVENT
    #
    # elsif self.classification == MessageClassification::ASK_CANCEL_EVENTS
    #   create_julie_action action_nature: JulieAction::JD_ACTION_CANCEL_MULTIPLE_EVENTS
    #
    # elsif self.classification == MessageClassification::ASSOCIATE_EVENT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_ASSOCIATE_EVENT
    #
    # elsif self.classification == MessageClassification::ASK_POSTPONE_EVENTS
    #   create_julie_action action_nature: JulieAction::JD_ACTION_POSTPONE_MULTIPLE_EVENTS
    #
    # elsif self.classification == MessageClassification::ASK_CREATE_EVENT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_CREATE_EVENT
    #
    # elsif self.classification == MessageClassification::UNKNOWN
    #   create_julie_action action_nature: JulieAction::JD_ACTION_FREE_ACTION
    # elsif self.classification == MessageClassification::FORWARD_TO_SUPPORT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_FORWARD_TO_SUPPORT
    #
    # elsif self.classification == MessageClassification::NOTHING_TO_DO
    #   create_julie_action action_nature: JulieAction::JD_ACTION_NOTHING_TO_DO
    # elsif self.classification == MessageClassification::FORWARD_TO_CLIENT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_FORWARD_TO_CLIENT
    # elsif self.classification == MessageClassification::WAIT_FOR_CONTACT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_WAIT_FOR_CONTACT
    # elsif self.classification == MessageClassification::FOLLOWUP_ON_WEEKLY_RECAP
    #   create_julie_action action_nature: JulieAction::JD_ACTION_FOLLOWUP_ON_WEEKLY_RECAP
    # elsif self.classification == MessageClassification::INVITATION_ALREADY_SENT
    #   create_julie_action action_nature: JulieAction::JD_ACTION_INVITATION_ALREADY_SENT
    # end
  end

  def has_data?
    CLASSIFICATIONS_WITH_DATA.include? classification
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
        THREAD_STATUS_HANDLED_BY_CLIENT,
        THREAD_STATUS_EVENTS_CREATION,
        THREAD_STATUS_OTHER
    ].freeze
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


  def previous_classification
    current_message = self.message
    return nil if current_message.blank?

    messages_thread = current_message.messages_thread
    return nil if messages_thread.blank?

    MessageClassification.where('message_id IN(?) AND created_at < ?', messages_thread.message_ids, current_message.received_at).order('id desc').first
  end


  def has_field?(field, options = {})
    scope = options.fetch(:scope, :classification)
    self.get_field(scope, field).present?
  end

  def missing_field?(field, options = {})
    !has_field?(field, options)
  end

  def get_field_from_attendees(attendees, field)
    case field
      when :skype
        attendees.find(&:has_skype?).try(:skype_id)
      when :any_number
        attendees.find(&:has_any_phone_number?).try(:any_phone_number)
      else
        nil
    end
  end

  def get_field_from_classification(field)
    case field
      when :location
        self.location
      else
        nil
    end
  end

  def get_field(scope, field)
    case scope
      when :thread_owner
        get_field_from_attendees([self.get_thread_owner_attendee], field)
      when :attendees
        get_field_from_attendees(self.get_present_attendees.reject(&:is_thread_owner), field)
      when :anyone
        get_field_from_attendees(self.get_present_attendees, field)
      when :classification
        get_field_from_classification(field)
      else
        nil
    end
  end

  private

  def clean_client_on_trip
    if self.client_on_trip.present?
      self.client_on_trip.delete('from_ai')
    end
  end

  def account
    self.message.try(:messages_thread).try(:account)
  end

  def account_appointment
    account.appointments.find{|appointment| appointment['label'] == self.appointment_nature}
  end

  def account_address
    account.addresses.find{|address| address['address'] == self.location}
  end
end
