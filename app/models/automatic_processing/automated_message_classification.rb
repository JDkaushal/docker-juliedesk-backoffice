class AutomaticProcessing::AutomatedMessageClassification < MessageClassification

  has_one :julie_action, class_name: "AutomaticProcessing::AutomatedJulieAction", foreign_key: :message_classification_id

  include TemplateGeneratorHelper
  include NotesGenerator
  
  def initialize(params = {})
    super(params)
  end

  def self.from_message_classification(message_classification)
    AutomaticProcessing::AutomatedMessageClassification.new(message_classification.attributes.reject{ |k,_| ['id', 'created_at', 'updated_at'].include?(k) })
  end

  def self.process_message(message)
    main_interpretation = message.main_message_interpretation
    main_interpretation = message.message_interpretations.find { |interpretation| interpretation.question == MessageInterpretation::QUESTION_MAIN } if main_interpretation.blank?

    message_classification = AutomaticProcessing::AutomatedMessageClassification.new(
      classification: main_interpretation.json_response['request_classif'],
      operator: "jul.ia@operator.juliedesk.com",
      message: message
    )

    message_classification.fill_form
    message_classification
  end

  def self.process_message!(message)
    message_classification = self.process_message(message)
    message_classification.save
    message_classification
  end

  def fill_form
    message = self.message
    message.populate_single_server_message

    main_message_interpretation = message.main_message_interpretation
    main_message_interpretation = message.message_interpretations.find { |interpretation| interpretation.question == MessageInterpretation::QUESTION_MAIN } if main_message_interpretation.blank?

    main_interpretation         = main_message_interpretation.json_response
    last_message_classification = self.previous_classification

    # Read attendees from last classif and merge with data interpreted by AI
    current_attendees  = Attendee.from_json(last_message_classification.try(:attendees) || '[]')
    attendees_from_ai  = get_attendees_from_interpretation(main_message_interpretation)
    Attendee.merge!(current_attendees, attendees_from_ai, { overwrite: false })

    location_from_ai = main_interpretation['location_data'].try(:[], 'address')
    #location_from_ai = main_interpretation['location_data'].try(:[], 'text') unless location_from_ai.present?

    # Build interpretation hash in backoffice format
    interpretation = {
        :classification       => main_interpretation['request_classif'],
        :appointment          => last_message_classification.try(:appointment_nature) || main_interpretation['appointment_classif'],
        :locale               => main_interpretation['language_detected'],
        :entities             => {},
        :attendees            => current_attendees,
        :constraints_data     => JSON.parse(last_message_classification.try(:constraints_data) || '[]') + (main_interpretation['constraints_data'] || []),
        :duration             => last_message_classification.try(:duration) || main_interpretation['duration'],
        :location             => last_message_classification.try(:location) || location_from_ai,
        :location_nature      => last_message_classification.try(:location_nature) || main_interpretation['location_data'].try(:[], 'location_nature'),
        :is_formal            => main_interpretation['formal_language'],
        :asap_constraint      => last_message_classification.try(:asap_constraint) || main_interpretation['asap'],
        :client_on_trip       => last_message_classification.try(:client_on_trip) || main_interpretation['client_on_trip']
    }

    # Build some other needed properties
    client_preferences = { timezone: account.default_timezone_id }

    # Compute Location
    appointment     = account.appointments.find{|appointment| appointment['kind'] == interpretation[:appointment] || appointment['label'] == interpretation[:appointment] }
    location_data   = compute_location_from_interpretation(interpretation, appointment)

    # Language Level
    is_formal = false
    is_formal ||= account.language_level == Account::LANGUAGE_LEVEL_FORMAL
    is_formal ||= interpretation[:is_formal]

    # Format Attendees
    attendees = interpretation[:attendees]

    # Duration
    default_duration = appointment.present? ? appointment['duration'] : nil

    AttendeeService.clean_and_categorize_clients!(attendees)
    AttendeeService.set_usage_names!(attendees, { locale: interpretation[:locale], is_formal: is_formal })

    self.assign_attributes({
        appointment_nature:  interpretation[:appointment],
        location:            location_data[:location],
        location_nature:     location_data[:location_nature],
        attendees:           attendees.map(&:to_h).to_json,
        date_times:          (main_interpretation['dates_to_check'] || []).to_json,
        locale:              interpretation[:locale],
        timezone:            client_preferences[:timezone],
        constraints_data:    interpretation[:constraints_data].to_json,
        duration:            interpretation[:duration] || default_duration,
        language_level:      is_formal ? Account::LANGUAGE_LEVEL_FORMAL : Account::LANGUAGE_LEVEL_NORMAL,
        asap_constraint:     interpretation[:asap_constraint],
        client_on_trip:      interpretation[:client_on_trip],

        # Used by AI to find the classification later
        identifier:          "#{self.message_id}-#{DateTime.now.to_i * 1000}",
        attendees_emails:    attendees.map(&:email)
    })


    if appointment.present?
      # Call instructions
      computed_call_instructions = AutomaticProcessing::Flows::CallInstructions.new(classification: self).process_flow('GET_CALL_INSTRUCTIONS')
      self.call_instructions = computed_call_instructions.to_json
      if self.is_virtual_appointment?
        computed_call_instructions.merge!(event_instructions: TemplateGeneration::CallInstructions.generate(self))
      end
      self.call_instructions = computed_call_instructions.to_json


      self.notes    = generate_notes
      self.summary  = generate_summary(account_appointment, get_present_attendees)
    end
  end



  def generate_summary(appointment, present_attendees)
    title_preferences = self.send(:account).try(:title_preferences)
    return self.message.try(:messages_thread).try(:subject) if title_preferences && title_preferences["general"] == 'email_subject'

    appointment = appointment.with_indifferent_access
    raise "Appointment config is missing" if appointment.blank?

    title_in_calendar_data = appointment['title_in_calendar']
    raise "Title in calendar for appointment is not defined" if title_in_calendar_data.blank?

    title_in_calendar = title_in_calendar_data[self.locale]

    title_in_calendar + " " + present_attendees.group_by(&:company).map{|company, attendees|
      attendees_list = attendees.map(&:full_name).join(', ')
      if company.present?
        attendees.length < 3 ? "#{company} [#{attendees_list}]" : company
      else
        attendees_list
      end
    }.join(" <> ")
  end

  private




  def compute_location_from_interpretation(interpretation, appointment_config)
    location_nature = nil

    # We have a location nature...
    if interpretation[:location_nature]
      address = account.addresses.select{|addr| addr['kind'] == interpretation[:location_nature]}.sort_by{|addr| addr['is_main_address'] ? 0 : 1}.first
      location_nature = interpretation[:location_nature]
      location = address['address'] if address
    end
    # Otherwise, we fallback to detected location text...
    location ||= interpretation[:location]

    # Otherwise, we fallback to default address for appointment type
    #if appointment_config && appointment_config['default_address']
    #  location ||= appointment_config['default_address']['address']
    #end

    { location: location, location_nature: location_nature}
  end


  def get_attendees_from_interpretation(main_interpretation)
    # Attendees information returned by conscience
    #
    thread_owner_account = main_interpretation.message.messages_thread.account
    contact_infos = main_interpretation.json_response.fetch('contacts_infos', [])

    names_to_identify_with_ai = contact_infos.select { |ci| ci['owner_email'].blank? }.map{ |ci| ci['owner_name'] }.compact

    thread_owner_account_all_emails = thread_owner_account.all_emails.map(&:downcase)


    recipients =  MessagesThread.contacts({server_messages_to_look: [self.message.try(:server_message)]}).map(&:with_indifferent_access).reject { |recipient| recipient[:email].include?("julie@") }
    recipients_emails = recipients.map { |recipient| recipient[:email] }

    # Retrieve attendee information from client contacts
    client_contacts = ClientContact.where(email: recipients_emails).order('updated_at desc').all

    clients_emails = JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get('clients_emails') || '[]')

    extracted_attendees = recipients.map do |recipient|
      # Backoffice data
      client_contact = client_contacts.find { |client_contact| client_contact.email == recipient[:email] }

      if client_contact.blank? || (client_contact && (client_contact.first_name.blank? || client_contact.last_name.blank?))
        human_civilities_response = AI_PROXY_INTERFACE.build_request(:parse_human_civilities, { fullname: recipient[:name], at: recipient[:email]})
        interpreted_first_name  = human_civilities_response['first_name']
        interpreted_last_name   = human_civilities_response['last_name']
        interpreted_gender      = human_civilities_response['gender']
      end

      if client_contact.blank? || (client_contact && client_contact.company.blank?)
        company_response = AI_PROXY_INTERFACE.build_request(:get_company_name, { address: recipient[:email], message: "" })
        interpreted_company = company_response['company']
      end

      Attendee.new(
        email:      recipient[:email],
        first_name: client_contact.try(:first_name)  || interpreted_first_name,
        last_name:  client_contact.try(:last_name)   || interpreted_last_name,
        gender:     client_contact.try(:gender)      || interpreted_gender,
        company:    client_contact.try(:company)     || interpreted_company,
        landline:   client_contact.try(:landline),
        mobile:     client_contact.try(:mobile),
        skype_id:   client_contact.try(:skypeId),
        status:     Attendee::STATUS_PRESENT,
        is_present: true,
        is_thread_owner: thread_owner_account_all_emails.include?(recipient[:email].downcase),
        is_client: clients_emails.include?(recipient[:email]),
        timezone:  client_contact.try(:timezone)
      )
    end

    # Try to Get owner email if AI could not find it the first time
    if names_to_identify_with_ai.present?
      contact_emails = AI_PROXY_INTERFACE.build_request(:who_are_we, { names: names_to_identify_with_ai, attendees: extracted_attendees.map{|recip| {email: recip.email, firstName: recip.first_name, lastName: recip.last_name}}})['data']

      contact_infos.each do |contact_info|
        email = contact_emails.find{|c_e| c_e['name'] == contact_info['owner_name']}.try(:[], 'email')
        contact_info['owner_email'] = email
      end
    end

    # New pass on attendees to actualize data we could get from AI
    extracted_attendees.each do |attendee|

      # Conscience data
      interpreted_landline = contact_infos.find { |contact_info| contact_info['owner_email'] == attendee.email && contact_info['tag'] == 'PHONE' && contact_info['value'] == 'landline' }.try(:fetch, 'text', nil)
      interpreted_mobile   = contact_infos.find { |contact_info| contact_info['owner_email'] == attendee.email && contact_info['tag'] == 'PHONE' && contact_info['value'] == 'mobile' }.try(:fetch, 'text', nil)
      interpreted_skype    = contact_infos.find { |contact_info| contact_info['owner_email'] == attendee.email && contact_info['tag'] == 'SKYPE' }.try(:fetch, 'text', nil)
      interpreted_timezone = contact_infos.find { |contact_info| contact_info['owner_email'] == attendee.email && contact_info['tag'] == 'TIMEZONE' }.try(:fetch, 'value', nil)

      # We favor timezone returned by AI, then fallback on what we already have or the thread owner default timezone
      attendee.timezone   = interpreted_timezone || attendee.timezone || thread_owner_account.default_timezone_id
      attendee.landline ||= interpreted_landline
      attendee.mobile   ||= interpreted_mobile
      attendee.skype_id ||= interpreted_skype
    end

    extracted_attendees
  end
end