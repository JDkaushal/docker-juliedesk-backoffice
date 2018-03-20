class AutomaticProcessing::AutomatedMessageClassification < MessageClassification
  include TemplateGeneratorHelper
  include NotesGenerator

  attr_reader :data_holder

  def initialize(params = {})
    @data_holder = params.delete(:data_holder)
    super(params)
  end

  def self.process_message_id(message, options={})

    message_classification = AutomaticProcessing::AutomatedMessageClassification.new(
      classification: message.main_message_interpretation.json_response['request_classif'],
      operator: "jul.ia@operator.juliedesk.com",
      message: message,
      data_holder: options[:data_holder]
    )

    message_classification.fill_form if message_classification.has_data?
    message_classification.save
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
              'fullName' => [human_civilities_response['first_name'], human_civilities_response['last_name']].select(&:present?).join(" "),
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
        is_formal: main_interpretation['formal_language'],
        asap_constraint: last_message_classification.try(:asap_constraint) || main_interpretation['asap']
    }

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
    # Otherwise, we fallback to detected location text...
    location ||= interpretation[:location]

    # Otherwise, we fallback to default address for appointment type
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
                               summary: nil,
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
                               language_level: is_formal ? Account::LANGUAGE_LEVEL_NORMAL : Account::LANGUAGE_LEVEL_NORMAL,
                               asap_constraint: interpretation[:asap_constraint],
                               attendees_emails: self.get_attendees_emails(attendees)
                           })


    self.notes = generate_notes

    if self.is_virtual_appointment?
      self.location = generate_call_instructions
    end

    self.summary = generate_summary
  end

  def generate_summary
    account_appointment['title_in_calendar'][self.locale] + " " + JSON.parse(self.attendees).select{|att| att['isPresent']}.group_by{|att| att['company']}.map{|company, attendees|
      attendees_list = attendees.map{|attendee| attendee['fullName']}.join(', ')
      if company.present?
        if attendees.length < 4
          "#{company} [#{attendees_list}]"
        else
          company
        end
      else
        attendees_list
      end
    }.join(" <> ")
  end

  private

  def account
    @data_holder.get_thread_owner_account
  end

  def account_appointment
    @data_holder.get_appointments.find{|appointment| appointment['label'] == self.appointment_nature}
  end

  def account_address
    @data_holder.get_addresses.find{|address| address['address'] == self.location}
  end
end