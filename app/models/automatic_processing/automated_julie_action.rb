class AutomaticProcessing::AutomatedJulieAction < JulieAction

  include TemplateGeneratorHelper
  include ApplicationHelper

  attr_accessor :chosen_date_for_check_availabilities, :data_holder

  def initialize(params = {})
    @data_holder = params.delete(:data_holder)

    super(params)
  end

  def process
    wordings = appointment_wordings

    if self.action_nature == JD_ACTION_SUGGEST_DATES
      self.date_times = find_dates_to_suggest.to_json


      self.text = "#{say_hi_text}#{get_suggest_dates_template({
                                                                  client_names: client_names,
                                                                  timezones: [client_timezone],
                                                                  default_timezone: client_timezone,
                                                                  locale: locale,
                                                                  is_virtual: false,
                                                                  attendees: attendees,
                                                                  appointment_in_email: {
                                                                      en: wordings['title_in_email']['en'],
                                                                      fr: wordings['title_in_email']['fr']
                                                                  },
                                                                  location_in_email: {
                                                                      en: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'en'),
                                                                      fr: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'fr')
                                                                  },
                                                                  should_ask_location: false,
                                                                  missing_contact_info: nil,
                                                                  dates: JSON.parse(self.date_times).map{|date_time| date_time['date']}
      })}"

    elsif self.action_nature == JD_ACTION_CHECK_AVAILABILITIES
      self.chosen_date_for_check_availabilities = choose_date_for_check_availabilities

      self.text = "#{say_hi_text}#{get_invitations_sent_template({
                                                                     client_names: client_names,
                                                                     timezones: [client_timezone],
                                                                     locale: self.message_classification.locale,
                                                                     is_virtual: false,
                                                                     attendees: attendees,
                                                                     appointment_in_email: {
                                                                         en: wordings['title_in_email']['en'],
                                                                         fr: wordings['title_in_email']['fr']
                                                                     },
                                                                     location_in_email: {
                                                                         en: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'en'),
                                                                         fr: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'fr')
                                                                     },
                                                                     should_ask_location: false,
                                                                     missing_contact_info: nil,
                                                                     date: self.chosen_date_for_check_availabilities
                                                                 })}"

    elsif self.action_nature == JD_ACTION_WAIT_FOR_CONTACT
      self.text = get_wait_for_contact_template({
                                                    locale: locale
                                              })
    else
      # elsif self.julie_action.action_nature == JD_ACTION_NOTHING_TO_DO
    #
    #
    # elsif self.action_nature == JD_ACTION_FORWARD_TO_SUPPORT
    #   self.text = get_forward_to_support_template({
    #                                                   locale: locale
    #                                               })
    #
    # elsif self.action_nature == JD_ACTION_FORWARD_TO_CLIENT
    #   self.text = get_forward_to_client_template({
    #                                                  locale: locale
    #                                              })
    end

    save

    handle_calendar
  end

  def handle_calendar
    if self.action_nature == JD_ACTION_CHECK_AVAILABILITIES

      response = EventsManagement::BaseInterface.new.build_request(:create, {
          email: account.email,
          summary: message_classification.summary,
          description: message_classification.notes,
          attendees: JSON.parse(message_classification.attendees).select{|a| (a['isPresent'] == 'true' || a['isPresent'] == true || a['status'] == 'optional' ) && a['email'].present?},
          location: message_classification.location,
          all_day: false,
          private: false,
          start: chosen_date_for_check_availabilities.to_s,
          end: (chosen_date_for_check_availabilities + message_classification.duration.minutes).to_s,
          start_timezone: client_timezone,
          end_timezone: client_timezone,
          calendar_login_username: account.email, #Warning, here it could be different for clients with calendar rules
          meeting_room: nil, # No support for meeting rooms for now
          create_skype_for_business_meeting: false # BNo support for sfb for now
      })

      if response && response['status'] == 'success'
        self.update({
                        calendar_id: response['data']['calendar_id'],
                        calendar_login_username: account.email,
                        event_id: response['data']['id']
                    })
      else
        raise AutomaticProcessing::Exceptions::EventCreationError.new(self.id)
      end
    end
  end

  private

  def find_dates_to_suggest
    date_suggestions_response = AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, {
        account_email: account.email,
        thread_data: incoming_message.messages_thread.computed_data([self.message_classification]),
        raw_constraints_data: JSON.parse(message_classification.constraints_data || "[]"),
        n_suggested_dates: 4,
        attendees: [],
        asap: message_classification.asap_constraint,
        message_id: nil # Keep this to nil, if set it is used to get previously suggested dates, if not set it causes errors
    })

    if !date_suggestions_response || date_suggestions_response[:error]
      raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionError.new(self.message_classification.message.id)
    end

    date_suggestions = date_suggestions_response['suggested_dates'] || []
    if date_suggestions.length < 2
      raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionNotEnoughSuggestionsError.new(self.message_classification.message.id)
    end

    date_suggestions.map{|date_suggestion|
      {
          timezone: client_timezone,
          date: date_suggestion
      }
    }
  end

  def choose_date_for_check_availabilities
    string_date_times = JSON.parse(self.message_classification.date_times || '[]')
    if string_date_times.length == 0
      raise AutomaticProcessing::Exceptions::ConscienceNoDatesToValidateError.new(self.message_classification.id)
    else
      DateTime.parse string_date_times[0]
    end
  end

  def say_hi_text
    text = get_say_hi_template({
                            recipient_names: attendees.map{|att| att[:assisted_by_name] || att[:name]},
                            should_say_hi: true,
                            locale: locale
                        })

    if text.present?
      "#{text}\n\n"
    else
      nil
    end
  end

  def incoming_message
    @data_holder.get_message
  end

  def locale
    @data_holder.get_current_locale
  end

  def account
    @data_holder.get_thread_owner_account
  end

  def client_timezone
    account.default_timezone_id
  end

  def appointment_wordings
    @data_holder.get_apppointment
  end

  def client_names
    @data_holder.get_client_names
  end

  def attendees
    @data_holder.get_present_attendees
  end
end