class MeetingService

  class MeetingError < StandardError ; end
  class MeetingNotScheduling < MeetingError ; end
  class NotAMeetingAttendee < MeetingError ; end
  class SuggestedDateNotFound < MeetingError ; end
  class AiComputingError < MeetingError ; end
  class DateNotAvailable < MeetingError ; end
  class NoThreadAccount < MeetingError ; end
  class FeatureNotEnabled < MeetingError ; end
  class UserNotFound < MeetingError ; end

  def initialize(messages_thread)
    @messages_thread = messages_thread
    @meeting_data_service = MeetingDataService.new(@messages_thread)
  end

  def get_limited_details
    data = @messages_thread.computed_data
    attendees = data[:attendees]

    {
      appointmentNature: data[:appointment_nature],
      duration: data[:duration],
      location: data[:location],
      attendeesNames: attendees.map{|attendee| attendee['name']},
      organizer: attendees.find { |attendee| attendee['isThreadOwner'] == 'true' }
    }
  end

  def get_user_details(user_email)
    user_details = @meeting_data_service.extract_user_details(user_email)

    if user_details.blank?
      raise UserNotFound
    end

    {
      timezone: user_details['timezone']
    }
  end

  def confirm_suggested_date(suggested_date, validator)
    raise NoThreadAccount.new("no account for thread #{@messages_thread.id}") unless @messages_thread.account.present?
    raise FeatureNotEnabled.new("this feature is not enabled") unless @messages_thread.account.call_to_action_in_email_enabled

    raise MeetingNotScheduling.new("Thread #{@messages_thread.id} is not scheduling") unless @messages_thread.scheduling_status == MessagesThread::SCHEDULING_EVENT
    attendees = JSON.parse(last_message_classification.attendees || '[]')
    attendees_emails = attendees.map { |attendee| attendee['email'] }

    raise NotAMeetingAttendee.new("#{validator} is not a thread attendee") unless attendees_emails.include?(validator)
    thread_suggested_dates = @messages_thread.last_suggested_date_times.map { |date_data| DateTime.parse(date_data['date']) }
    #raise SuggestedDateNotFound.new("#{suggested_date} was not found in suggested dates") unless thread_suggested_dates.find { |date| date == suggested_date }

    # Verify availability
    available_slot = self.verify_date_suggestion(suggested_date)

    if available_slot.present?
      confirmed_date = available_slot[:date]
      timezone       = available_slot[:timezone]

      # Classify
      generated_classification  = classify!(suggested_date)
      generated_classification.update_attributes!({ verified_dates_by_ai: { verified_dates: [confirmed_date], timezone: timezone } })

      # Generate julie ation
      generated_julie_action = create_julie_action!(generated_classification)
      generated_julie_action.text = generate_template(generated_julie_action)

      # Create event
      event_data = create_event(generated_julie_action)
      generated_julie_action.update(event_data.merge(calendar_login_username: @messages_thread.account.email))

      # Deliver email
      email_server_response = deliver_message!(generated_julie_action)
      generated_julie_action.update({ server_message_id: email_server_response['id'], done: true })

      # Archive thread
      archive_thread!(generated_classification)
      confirmed_date
    else
      nil
    end
  end

  def verify_date_suggestion(slot_date)
    attendees = JSON.parse(last_message_classification.attendees || '[]')

    validation_response = AI_PROXY_INTERFACE.build_request(:verify_dates_v11, {
        server_message_id: last_message_classification.message.server_message_id,
        dates_to_check: [slot_date.utc.strftime('%Y-%m-%dT%H:%M:%S')],
        account_email: @messages_thread.account_email,
        attendees: attendees,
        thread_data: {
            appointment_nature: last_message_classification.appointment_nature,
            location: last_message_classification.location,
            duration: last_message_classification.duration,
            timezone: last_message_classification.timezone
        }
    })

    raise AiComputingError.new("AI verify_dates_v11 call failed") if validation_response['status'] != 'success'
    validated_dates = validation_response['dates_validate']
    validated_dates.present? ? { timezone: validation_response['timezone'], date: DateTime.parse(validated_dates.first['date']) } : nil
  end

  private

  def last_message_classification
    @last_message_classification ||= @messages_thread.last_message_classification_with_data
  end

  def classify!(suggested_date)
    message_classification = MessageClassification.new(
        classification: MessageClassification::ASK_AVAILABILITIES,
        operator: "slash@juliedesk.com",
        message: last_message_classification.message,
        date_times: [suggested_date.strftime('%FT%T%:z')]
    )
    message_classification.assign_attributes(
        last_message_classification.attributes.with_indifferent_access.slice(
            :appointment_nature, :location, :location_nature, :attendees, :locale, :timezone, :constraints_data,
            :duration, :language_level, :asap_constraint, :client_on_trip, :attendees_emails, :call_instructions, :notes, :summary)
    )

    message_classification.save
    message_classification
  end

  def create_julie_action!(message_classification)
    JulieAction.create(
        action_nature: message_classification.computed_julie_action_nature,
        message_classification: message_classification
    )
  end


  def get_current_appointment(appointment_nature)
    owner_account = @messages_thread.account
    return nil if owner_account.nil?
    appointments = owner_account.appointments || []
    appointments.find{|appointment| appointment['kind'] == appointment_nature }
  end

  def is_appointment_virtual?(message_classification)
    appointment = get_current_appointment(message_classification.appointment_nature)
    return false if appointment.nil?
    appointment['appointment_kind_hash']['is_virtual']
  end


  def create_event(julie_action)
    event_data = @meeting_data_service.generate_event_data(julie_action)
    response = EventsManagement::BaseInterface.new.build_request(:create, event_data)
    raise AutomaticProcessing::Exceptions::EventCreationError.new(julie_action.id) unless response && response['status'] == 'success'
    { calendar_id: response['data']['calendar_id'], event_id: response['data']['id'] }
  end


  def generate_template(julie_action)
    message_classification  = julie_action.message_classification
    wordings = get_current_appointment(message_classification.appointment_nature)
    formatted_attendees = message_classification.get_present_attendees.reject(&:is_client).map do |attendee|
      { name: attendee.usage_name, assisted_by_name: nil, email: attendee.email }
    end

    data = {
        client_names: message_classification.get_present_attendees.select(&:is_client).map(&:usage_name),
        timezones: [message_classification.verified_dates_by_ai['timezone']],
        locale: message_classification.locale,
        is_virtual: is_appointment_virtual?(message_classification),
        attendees: formatted_attendees,
        appointment_in_email: { en: wordings['title_in_email']['en'], fr: wordings['title_in_email']['fr'] },
        location_in_email: {
            en: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'en'),
            fr: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'fr')
        },
        location: message_classification.location,
        location_is_settled: message_classification.location.present?,
        should_ask_location: @meeting_data_service.should_ask_location?(julie_action),
        missing_contact_info: @meeting_data_service.missing_contact_info(julie_action),
        date: message_classification.verified_dates_by_ai['verified_dates'].first
    }
    TemplateService.new.generate_send_invitations(@meeting_data_service.recipients_names(julie_action), data)
  end


  def archive_thread!(message_classification)
    thread_status = message_classification.computed_thread_status
    message_classification.update(thread_status: thread_status)

    EmailServer.archive_thread(messages_thread_id: @messages_thread.server_thread_id)
    @messages_thread.messages.update_all(archived: true)

    thread_params = { should_follow_up: false, status: thread_status, in_inbox: false }
    if thread_params[:status] == MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED
      thread_params[:aborted_at] = DateTime.now
    end

    @messages_thread.update(thread_params)
    WebSockets::Manager.trigger_archive(@messages_thread.id)
  end


  def deliver_message!(julie_action)
    message_classification = julie_action.message_classification
    initial_recipients = @meeting_data_service.initial_recipients(julie_action)
    recipients_to = initial_recipients[:to]
    recipients_cc = initial_recipients[:cc]

    if julie_action.action_nature == JulieAction::JD_ACTION_WAIT_FOR_CONTACT
      recipients_to = [initial_recipients[:client]]
      recipients_cc = []
    end

    EmailServer.deliver_message({
      subject: @messages_thread.subject,
      from: @messages_thread.julie_alias.generate_from,
      to: recipients_to.join(", "),
      cc: recipients_cc.join(", "),
      html: TemplateService.new.generate_reply_message_html(@messages_thread.julie_alias, julie_action.text, { locale: message_classification.locale }),
      quote_forward_message: false,
      reply_to_message_id: message_classification.message.try(:server_message_id)
    })
  end

end
