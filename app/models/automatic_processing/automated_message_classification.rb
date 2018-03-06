class AutomaticProcessing::AutomatedMessageClassification < MessageClassification
  include TemplateGeneratorHelper

  def self.process_message_id(message_id, options={})
    message = Message.find(message_id)

    message.interprete(options[:force_reinterpretation].present?)

    raise "No account associated" unless message.messages_thread.account
    raise "Conscience could not interprete message" unless message.main_message_interpretation

    message_classification = AutomaticProcessing::AutomatedMessageClassification.new(
        classification: message.main_message_interpretation.json_response['request_classif'],
        operator: "jul.ia@operator.juliedesk.com"
    )

    message_classification.message = message

    message_classification.fill_form if message_classification.has_data?
    message_classification.julie_action = AutomaticProcessing::AutomatedJulieAction.new(
        action_nature: message_classification.computed_julie_action_nature
    )
    message_classification.julie_action.process
    message_classification.save

    message_classification.julie_action.handle_calendar
    message_classification.julie_action.deliver_message
    message_classification.archive_thread
  end


  def fill_form
    message = self.message
    message.populate_single_server_message
    main_interpretation = message.main_message_interpretation.json_response

    last_message_classification = message.messages_thread.last_message_classification_with_data


    # Build interpretation hash in backoffice format
    interpretation = {
        :classification => main_interpretation['request_classif'],
        :appointment => last_message_classification.try(:appointment_nature) || main_interpretation['appointment_classif'],
        :locale => main_interpretation['language_detected'],
        :entities => {},
        attendees: (last_message_classification.try(:attendees) && JSON.parse(last_message_classification.try(:attendees)).length > 0) ? JSON.parse(last_message_classification.attendees) : MessagesThread.contacts({server_messages_to_look: [message.server_message]}).map do |att|
          human_civilities_response = AI_PROXY_INTERFACE.build_request(:parse_human_civilities, { fullname: att[:name], at: att[:email]})
          company_response = AI_PROXY_INTERFACE.build_request(:get_company_name, { address: att[:email], message: "" })

          {
              'email' => att[:email],
              'fullName' => att[:name],
              'firstName' => human_civilities_response['first_name'],
              'lastName' => human_civilities_response['last_name'],
              'gender' => human_civilities_response['gender'],
              'company' => company_response['company'],
              'isPresent' => true
          }
        end,
        constraints_data: JSON.parse(last_message_classification.try(:constraints_data) || '[]') + (main_interpretation['constraints_data'] || []),
        duration: last_message_classification.try(:duration) || main_interpretation['duration'],
        location: last_message_classification.try(:location) || main_interpretation['location_data'].try(:[], 'text'),
        location_nature: last_message_classification.try(:location_nature) || main_interpretation['location_data'].try(:[], 'location_nature'),
        is_formal: main_interpretation['formal_language']
    }

    account = message.messages_thread.account

    # Build some other needed properties
    client_preferences = {
        timezone: account.default_timezone_id,
    }
    appointment = account.appointments.find{|appointment| appointment['label'] == interpretation[:appointment]}
    target = {
        "propose" => "client",
        "ask_interlocutor" => "interlocutor",
        "later" => "later"
    }[appointment["behaviour"]] || "later"


    # Compute location
    location_nature = nil
    # We have a location nature...
    if interpretation[:location_nature]
      address = account.addresses.select{|addr| addr['kind'] == interpretation[:location_nature]}.sort_by{|addr| addr['is_main_address'] ? 0 : 1}.first
      # ...and a corresponding address
      if address
        location = address['address']
        location_nature = interpretation[:location_nature]
      end
    end
    # Otherwise, we fallback to detected location text or default address for appointment type
    location ||= interpretation[:location]
    location ||= appointment['default_address'].try(:[], 'address')


    is_formal = false
    is_formal ||= account.language_level == Account::LANGUAGE_LEVEL_FORMAL
    is_formal ||= interpretation[:is_formal]

    attendees = self.class.clean_and_categorize_clients(interpretation[:attendees])
    attendees.each do |attendee|
      attendee['usageName'] = get_usage_name({
                                                 locale: interpretation[:locale],
                                                 first_name: attendee['firstName'],
                                                 last_name: attendee['lastName'],
                                                 gender: "#{attendee['gender']}".first,
                                                 formal: is_formal
                                             })
    end

    self.assign_attributes({
                               appointment_nature: interpretation[:appointment],
                               summary: message.server_message['subject'], # No support for client and companies subject for now
                               location: location,
                               location_nature: location_nature,
                               attendees: attendees.to_json,
                               notes: nil,
                               date_times: (main_interpretation['dates_to_check'] || []).to_json,
                               locale: interpretation[:locale],
                               timezone: client_preferences[:timezone],
                               constraints_data: interpretation[:constraints_data].to_json,
                               duration: interpretation[:duration] || appointment['duration'],
                               call_instructions: {
                                   target: target,
                                   support: 'mobile',
                                   targetInfos: {}
                               }.to_json,
                               language_level: is_formal ? Account::LANGUAGE_LEVEL_NORMAL : Account::LANGUAGE_LEVEL_NORMAL
                           })
  end


  def archive_thread
    self.thread_status = self.computed_thread_status
    EmailServer.archive_thread(messages_thread_id: self.message.messages_thread.server_thread_id)

    self.message.messages_thread.messages.update_all(archived: true)

    self.message.messages_thread.update({
                                           should_follow_up: false,
                                           status: self.thread_status,
                                           in_inbox: false
                                       })

    WebSockets::Manager.trigger_archive(self.message.messages_thread.id)
  end

end