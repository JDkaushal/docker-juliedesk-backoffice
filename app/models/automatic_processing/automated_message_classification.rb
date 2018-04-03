class AutomaticProcessing::AutomatedMessageClassification < MessageClassification
  include TemplateGeneratorHelper
  include NotesGenerator

  #attr_reader :data_holder

  class NoDataHolderError < StandardError
  end

  def initialize(params = {})
    super(params)
  end

  def self.process_message(message, options={})
    message_classification = AutomaticProcessing::AutomatedMessageClassification.new(
      classification: message.main_message_interpretation.json_response['request_classif'],
      operator: "jul.ia@operator.juliedesk.com",
      message: message
    )

    message_classification.fill_form if message_classification.has_data?
    message_classification.save

    message_classification
  end

  def fill_form
    message = self.message
    message.populate_single_server_message

    main_interpretation         = message.main_message_interpretation.json_response
    last_message_classification = message.messages_thread.last_message_classification_with_data

    existing_attendees  = Attendee.from_json(last_message_classification.try(:attendees) || '[]')
    current_attendees   = existing_attendees
    current_attendees   = get_attendees_from_interpretation(main_interpretation) if existing_attendees.blank?

    # Build interpretation hash in backoffice format
    interpretation = {
        :classification       => main_interpretation['request_classif'],
        :appointment          => last_message_classification.try(:appointment_nature) || main_interpretation['appointment_classif'],
        :locale               => main_interpretation['language_detected'],
        :entities             => {},
        :attendees            => current_attendees,
        :constraints_data     => JSON.parse(last_message_classification.try(:constraints_data) || '[]') + (main_interpretation['constraints_data'] || []),
        :duration             => last_message_classification.try(:duration) || main_interpretation['duration'],
        :location             => last_message_classification.try(:location) || main_interpretation['location_data'].try(:[], 'text'),
        :location_nature      => last_message_classification.try(:location_nature) || main_interpretation['location_data'].try(:[], 'location_nature'),
        :is_formal            => main_interpretation['formal_language'],
        :asap_constraint      => last_message_classification.try(:asap_constraint) || main_interpretation['asap'],
        :client_on_trip       => last_message_classification.try(:client_on_trip) || main_interpretation['client_on_trip']
    }

    # Build some other needed properties
    client_preferences = { timezone: account.default_timezone_id }
    appointment = account.appointments.find{|appointment| appointment['label'] == interpretation[:appointment]}

    # Compute Location
    location_data   = compute_location_from_interpretation(interpretation, appointment)

    # Language Level
    is_formal = false
    is_formal ||= account.language_level == Account::LANGUAGE_LEVEL_FORMAL
    is_formal ||= interpretation[:is_formal]

    # Format Attendees
    attendees = interpretation[:attendees]
    AttendeeService.clean_and_categorize_clients!(attendees)
    AttendeeService.set_usage_names!(attendees, { locale: interpretation[:locale], is_formal: is_formal })

    self.assign_attributes({
        appointment_nature:  interpretation[:appointment],
        summary:             nil,
        location:            location_data[:location],
        location_nature:     location_data[:location_nature],
        attendees:           attendees.map(&:to_h).to_json,
        notes:               nil,
        date_times:          (main_interpretation['dates_to_check'] || []).to_json,
        locale:              interpretation[:locale],
        timezone:            client_preferences[:timezone],
        constraints_data:    interpretation[:constraints_data].to_json,
        duration:            interpretation[:duration] || appointment['duration'],
        language_level:      is_formal ? Account::LANGUAGE_LEVEL_FORMAL : Account::LANGUAGE_LEVEL_NORMAL,
        asap_constraint:     interpretation[:asap_constraint],
        client_on_trip:      interpretation[:client_on_trip],
        # Used by AI to find the classification later
        identifier:          "#{self.message_id}-#{DateTime.now.to_i * 1000}",
        attendees_emails:    attendees.map(&:email)
    })

    # Call instructions
    self.call_instructions = AutomaticProcessing::Flows::CallInstructions.new(classification: self).process_flow('GET_CALL_INSTRUCTIONS').to_json

    self.notes    = generate_notes
    self.location = generate_call_instructions if self.is_virtual_appointment?
    self.summary  = generate_summary
  end



  def generate_summary
    account_appointment['title_in_calendar'][self.locale] + " " + get_present_attendees.group_by(&:company).map{|company, attendees|
      attendees_list = attendees.map(&:full_name).join(', ')
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


  def archive_thread
    thread_status = self.computed_thread_status

    self.thread_status = thread_status

    self.save
    EmailServer.archive_thread(messages_thread_id: self.message.messages_thread.server_thread_id)

    self.message.messages_thread.messages.update_all(archived: true)

    thread_params = {
        should_follow_up: false,
        status: self.thread_status,
        in_inbox: false
    }

    if thread_params[:status] == MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED
      thread_params[:aborted_at] = DateTime.now
    end

    self.message.messages_thread.update(thread_params)

    WebSockets::Manager.trigger_archive(self.message.messages_thread.id)
  end


  def has_field?(field, options = {})
    scope = options.fetch(:scope, :classification)
    return nil unless [:thread_owner, :attendees, :anyone].include?(scope)
    self.get_field(field, scope).present?
  end

  def missing_field?(field, options = {})
    !has_field?(field, options)
  end

  def get_field(field, from)
    return nil if account.nil?
    return nil unless [:thread_owner, :attendees, :anyone].include?(from)

    present_attendees = self.get_present_attendees.reject(&:is_thread_owner)

    if field == :location
      self.location
    elsif field == :skype
      from == :thread_owner ? account.skype : present_attendees.find(&:has_skype?).try(:skype_id)
    elsif field == :any_number
      from == :thread_owner ? account.any_phone_number : present_attendees.find(&:has_any_phone_number?).try(:any_phone_number)
    else
      nil
    end
  end


  def get_attendees
    return [] if self.attendees.blank?
    Attendee.from_json(self.attendees)
  end

  def get_present_attendees
    self.get_attendees.select(&:present?)
  end

  def get_thread_owner_attendee
    self.get_present_attendees.find(&:is_thread_owner)
  end

  def get_client_attendees
    self.get_attendees.select(&:is_client)
  end

  def get_non_client_attendees
    self.get_attendees.reject(&:is_client)
  end

  def get_attendees_from_same_company
    account_company = account.try(:company)
    return [] if account_company.blank?

    self.get_attendees.select { |attendee| attendee.company == account_company }
  end

  def get_attendees_from_other_companies
    account_company = account.try(:company)
    self.get_attendees.select { |attendee| attendee.company != account_company }
  end

  def get_present_attendee_by_email(email)
    get_present_attendees.find { |attendee| attendee.email == email }
  end

  private

  def account
    self.message.messages_thread.account
  end

  def account_appointment

    account.appointments.find{|appointment| appointment['label'] == self.appointment_nature}
  end

  def account_address
    account.addresses.find{|address| address['address'] == self.location}
  end


  def compute_location_from_interpretation(interpretation, appointment_config)
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
    location ||= appointment_config['default_address'].try(:[], 'address')

    { location: location, location_nature: location_nature}
  end


  def get_attendees_from_interpretation(main_interpretation)
    # Attendees information returned by conscience
    contact_infos = main_interpretation.fetch('contacts_infos', [])

    recipients =  MessagesThread.contacts({server_messages_to_look: [self.message.try(:server_message)]}).map(&:with_indifferent_access)
    recipients_emails = recipients.map { |recipient| recipient[:email] }

    # Retrieve attendee information from client contacts
    client_contacts = ClientContact.where(email: recipients_emails).order('updated_at desc').all

    clients_emails = JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get('clients_emails') || '[]')

    recipients.map do |recipient|
      # Backoffice data
      client_contact = client_contacts.find { |client_contact| client_contact.email == recipient[:email] }

      # Conscience data
      interpreted_landline = contact_infos.find { |contact_info| contact_info['owner'] == recipient[:email] && contact_info['tag'] == 'PHONE' && contact_info['value'] == 'landline' }.try(:fetch, 'text', nil)
      interpreted_mobile   = contact_infos.find { |contact_info| contact_info['owner'] == recipient[:email] && contact_info['tag'] == 'PHONE' && contact_info['value'] == 'mobile' }.try(:fetch, 'text', nil)
      interpreted_skype    = contact_infos.find { |contact_info| contact_info['owner'] == recipient[:email] && contact_info['tag'] == 'SKYPE' }.try(:fetch, 'text', nil)

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
        landline:   client_contact.try(:landline)    || interpreted_landline,
        mobile:     client_contact.try(:mobile)      || interpreted_mobile,
        skype_id:   client_contact.try(:skypeId)     || interpreted_skype,
        status:     Attendee::STATUS_PRESENT,
        is_present: true,
        is_thread_owner: recipient['isThreadOwner'] == 'true',
        is_client: clients_emails.include?(recipient[:email])
      )
    end
  end

end