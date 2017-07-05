class AutoMessageClassification < MessageClassification

  include ApplicationHelper
  extend ApplicationHelper
  extend TemplateGeneratorHelper
  has_many :auto_message_classification_reviews

  self.table_name = "auto_message_classifications"

  def clean_delete
    self.julie_action.delete
    self.auto_message_classification_reviews.each do |amcr|
      amcr.delete
    end
    self.delete
  end

  def self.generate_batch_identifier params={}
    start_date = params[:start_date] || raise("Missing argument start_date")
    end_date = params[:end_date] || raise("Missing argument end_date")
    now = DateTime.now
    batchs_count = AutoMessageClassification.select(:batch_identifier).uniq.count

    "Batch ##{batchs_count +1} | #{start_date.strftime("%Y-%m-%d")} - #{end_date.strftime("%Y-%m-%d")} | compiled #{now.strftime("%B %Y")}"
  end

  def self.populate_turing params={}
    # Get params
    start_date = params[:start_date] || raise("Missing argument start_date")
    end_date = params[:end_date] || raise("Missing argument end_date")
    batch_identifier = params[:batch_identifier] || self.generate_batch_identifier(start_date: start_date, end_date: end_date)
    target_count = params[:target_count] || 100
    force_reinterpretation = params[:dont_force_reinterpretation].blank?


    # Get messages_thread_ids with messages received during period
    messages_thread_ids = Message.where(from_me: false).where("received_at >= ? AND received_at < ?", start_date, end_date).select(:messages_thread_id).distinct.map(&:messages_thread_id)

    # Get messages_ids first-of-thread received during period
    fot_message_ids = Message.where(messages_thread_id: messages_thread_ids).select(:received_at, :id, :messages_thread_id).group_by(&:messages_thread_id).map do |messages_thread_id, messages|
      messages.sort_by(&:received_at).first
    end.select do |message|
      message.received_at >= start_date && message.received_at < end_date
    end.map(&:id)

    # Get those classified as ask_date_suggestion by AI
    fot_message_ids_sd = MessageInterpretation.where(message_id: fot_message_ids, question: "main", error: false).select{|mi|
      mi.json_response && mi.json_response["request_classif"] == "ask_date_suggestions"
    }.map(&:message_id)

    # Retrieve message_ids not already associated to an auto_message_classification, and sample them
    used_message_ids = AutoMessageClassification.where(message_id: fot_message_ids_sd).map(&:message_id)
    unused_message_ids = Message.where(id: fot_message_ids_sd).where.not(id: used_message_ids).select(:id).map(&:id)
    unused_message_ids = unused_message_ids.sample(unused_message_ids.length)


    unused_message_ids.each do |mid|
      amcs_count = AutoMessageClassification.where(batch_identifier: batch_identifier, from_ai: true).count
      print "\n#{amcs_count}/#{target_count}..."
      if amcs_count < target_count
        begin
          amc = AutoMessageClassification.build_from_conscience(mid, force_reinterpretation: force_reinterpretation)[:auto_message_classification]
          amc.batch_identifier = batch_identifier
          amc.save
        rescue Exception => e
          print "\nImpossible to generate an auto_message_classification: #{e}"
        end
      else
        print "\n#{batch_identifier} is now complete with #{amcs_count} auto_message_classifications"
        return true
      end
    end

    amcs_count = AutoMessageClassification.where(batch_identifier: batch_identifier, from_ai: true).count
    print "Can't complete #{batch_identifier}. Only #{amcs_count} auto_messages_classifications generated"
    return false
  end

  def auto_message_classification_review operator_id
    auto_message_classification_reviews.find{|amcr| "#{amcr.operator_id}" == "#{operator_id}" }
  end

  def notation operator_id
    auto_message_classification_review(operator_id).try(:notation)
  end

  def mark_as_solved? operator_id
    auto_message_classification_review(operator_id).try(:resolved)
  end

  def notation_comments operator_id
    auto_message_classification_review(operator_id).try(:comments)
  end

  def self.build_from_operator message_id, params={}
    m = Message.find(message_id)

    mc = m.message_classifications.select{|mc| mc.julie_action.done}.first
    ja = mc.julie_action.dup
    amc = AutoMessageClassification.new(mc.dup.attributes.reject{|k, v| ['verified_dates_by_ai', 'annotated_reply', 'language_level'].include? k})
    amc.julie_action = ja
    amc.from_ai = false

    m.auto_message_classification = amc
  end

  def self.get_all_batch_identifiers
    self.select(:batch_identifier).distinct.map(&:batch_identifier).compact
  end


  def self.clean_and_categorize_clients attendees
    accounts = Account.get_active_account_emails(detailed: true)
    attendees.map do |attendee|
      attendee_email = attendee['email']
      if attendee_email.present?
        accounts.select do |account|
          all_emails = [account['email']] + account['email_aliases']
          if all_emails.include?(attendee_email)
            attendee['account_email'] = account['email']
            attendee['usage_name'] = account['usage_name']
            attendee['usageName'] = account['usage_name']
            attendee['firstName'] = account['first_name']
            attendee['lastName'] = account['last_name']
          end
        end
        attendee['email'] = attendee_email.gsub(" ", "")
      end
      attendee
    end
  end

  def self.build_from_conscience message_id, params={}
    result = {}

    # Get objects
    m = Message.find(message_id)
    account = m.messages_thread.account

    # Verify account exists
    raise "No account associated" unless account
    raise "Associated account #{account.email} has current notes" unless account.current_notes.blank?

    # Import server messages and associate the first-of-thread message
    m.messages_thread.re_import
    m = m.messages_thread.messages.find{|me| me.id == m.id}

    # Verify client sent the email
    # Skipped - not needed
    # from_email = ApplicationHelper.strip_email(m.server_message['from'])
    # raise "Client is not the sender" unless account.all_emails.map(&:downcase).include? "#{from_email}".downcase


    # Verify it's not multi-clients
    to_emails = ApplicationHelper.find_addresses("#{m.server_message['to']}").addresses.map(&:address)
    cc_emails = ApplicationHelper.find_addresses("#{m.server_message['cc']}").addresses.map(&:address)
    all_emails = ([from_email] + to_emails + cc_emails).uniq
    all_account_emails = all_emails.map{|email| Account.find_account_email(email, {})}.compact.uniq
    raise "Multi-clients: #{all_account_emails.join(", ")}" if all_account_emails.length >= 1

    processing_date = m.received_at + 5.minutes

    # Get interpretations
    main_message_interpretation = m.message_interpretations.find{|mi| mi.question == "main"}
    entities_interpretation = m.message_interpretations.find{|mi| mi.question == "entities"}
    if params[:force_reinterpretation]
      main_message_interpretation.process
      entities_interpretation.process
    end




    if main_message_interpretation.present?
      main_interpretation = JSON.parse(main_message_interpretation.raw_response)

      computed_data = m.messages_thread.computed_data

      # Build interpretation hash in backoffice format
      interpretation = {
          :classification => main_interpretation["request_classif"],
          :appointment => computed_data[:appointment_nature] || main_interpretation['appointment_classif'],
          :locale => main_interpretation["language_detected"],
          :entities => {},
          attendees: computed_data[:attendees] || MessagesThread.contacts({server_messages_to_look: [m.server_message]}).map do |att|
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
          constraints_data: main_interpretation['constraints_data'],
          duration: computed_data[:duration] || main_interpretation['duration'],
          location: computed_data[:location] || main_interpretation['location_data'].try(:[], 'text'),
          location_nature: computed_data[:location_nature] || main_interpretation['location_data'].try(:[], 'location_nature'),
          is_formal: main_interpretation['formal_language']
      }





      klass = AutoMessageClassification
      if params[:for_real]
        klass = MessageClassification
      end


      # Build AutoMessageClassification
      amc = klass.new({
                          classification: interpretation[:classification]
                      })

      if amc.has_data?
        unless account
          raise "No account found for messages_thread ##{m.messages_thread_id} (account_email is #{m.messages_thread.account_email})"
        end

        # Build some other needed properties
        client_preferences = {
            timezone: account.default_timezone_id,
        }
        appointment = account.appointments.find{|appt| appt['label'] == interpretation[:appointment]}
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

        attendees = AutoMessageClassification.clean_and_categorize_clients(interpretation[:attendees])
        attendees.each do |attendee|
          attendee['usageName'] = get_usage_name({
                                                     locale: interpretation[:locale],
                                                     first_name: attendee['firstName'],
                                                     last_name: attendee['lastName'],
                                                     gender: "#{attendee['gender']}".first,
                                                     formal: is_formal
                                                 })
        end

        amc.assign_attributes({
                                  appointment_nature: interpretation[:appointment],
                                  summary: nil,
                                  location: location,
                                  location_nature: location_nature,
                                  attendees: attendees.to_json,
                                  notes: nil,
                                  date_times: '[]',
                                  locale: interpretation[:locale],
                                  timezone: client_preferences[:timezone],
                                  constraints_data: ((computed_data[:constraints_data] || []) + (interpretation[:constraints_data] || [])).to_json,
                                  duration: interpretation[:duration] || appointment['duration'],
                                  call_instructions: {
                                      target: target,
                                      support: "mobile",
                                      targetInfos: {}
                                  }.to_json,
                                  language_level: is_formal ? Account::LANGUAGE_LEVEL_NORMAL : Account::LANGUAGE_LEVEL_NORMAL
                              })

      end

      amc.julie_action = JulieAction.new({
                                             action_nature: amc.computed_julie_action_nature,
                                             done: true,
                                             server_message_id: m.server_message_id,
                                         })


      if amc.julie_action.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES

        #puts "*" * 50
        # Handle calendar
        date_suggestions_response = AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, {
            account_email: account.email,
            thread_data: m.messages_thread.computed_data([amc]),
            raw_constraints: interpretation[:constraints_data],
            n_suggested_dates: 4,
            attendees: [],
            message_id: m.id,
            date: processing_date.strftime("%Y-%m-%d")
        })
        #puts date_suggestions_response
        date_suggestions = date_suggestions_response["suggested_dates"]
        if date_suggestions.length < 2
          raise "Less than two dates found for suggestions. Not able to continue."
        end
        amc.julie_action.date_times = (date_suggestions || []).map{|ds| {timezone: amc.timezone, date: ds}}.to_json

        # Handle template generation
        client_names = interpretation[:attendees].select{|att| att['isPresent'] && att['account_email']}.map do |att|
          att['usageName']
        end

        attendees = interpretation[:attendees].select{|att| att['isPresent'] && !att['account_email']}.map do |att|
          {
              name: att['usageName']
          }
        end

        data_for_template = {
            client_names: client_names,
            timezones: [client_preferences[:timezone]],
            default_timezone: client_preferences[:timezone],
            locale: interpretation[:locale],
            is_virtual: false,
            attendees: attendees,
            appointment_in_email: {
                en: appointment['title_in_email']['en'],
                fr: appointment['title_in_email']['fr']
            },
            location_in_email: {
                en: appointment['default_address'].try(:[], 'address_in_template').try(:[], 'en'),
                fr: appointment['default_address'].try(:[], 'address_in_template').try(:[], 'fr')
            },
            should_ask_location: false,
            missing_contact_info: nil,

            dates: date_suggestions
        }

        text_template = get_suggest_dates_template data_for_template

        say_hi_text = get_say_hi_template({
                                              recipient_names: attendees.map{|att| att[:assisted_by_name] || att[:name]},
                                              should_say_hi: true,
                                              locale: interpretation[:locale]
                                          })

        if say_hi_text.present?
          say_hi_text = "#{say_hi_text}\n\n"
        end

        amc.julie_action.text = "#{say_hi_text}#{text_template}"
      elsif amc.julie_action.action_nature == JulieAction::JD_ACTION_CHECK_AVAILABILITIES

        amc.date_times = (main_interpretation["dates_to_check"] || []).to_json
        raise "No date was found in response" if amc.date_times.length == 0
        #raise "Several dates were found in response" if amc.date_times.length > 1

        date = JSON.parse(amc.date_times).first

        client_names = interpretation[:attendees].select{|att| att['isPresent'] && att['account_email']}.map do |att|
          att['usageName']
        end

        attendees = interpretation[:attendees].select{|att| att['isPresent'] && !att['account_email']}.map do |att|
          {
              name: att['usageName']
          }
        end

        data_for_template = {
            client_names: client_names,
            timezones: [client_preferences[:timezone]],
            locale: interpretation[:locale],
            is_virtual: false,
            attendees: attendees,
            appointment_in_email: {
                en: appointment['title_in_email']['en'],
                fr: appointment['title_in_email']['fr']
            },
            location_in_email: {
                en: appointment['default_address'].try(:[], 'address_in_template').try(:[], 'en'),
                fr: appointment['default_address'].try(:[], 'address_in_template').try(:[], 'fr')
            },
            should_ask_location: false,
            missing_contact_info: nil,

            date: date
        }

        text_template = get_invitations_sent_template data_for_template

        say_hi_text = get_say_hi_template({
                                              recipient_names: attendees.map{|att| att[:assisted_by_name] || att[:name]},
                                              should_say_hi: true,
                                              locale: interpretation[:locale]
                                          })

        if say_hi_text.present?
          say_hi_text = "#{say_hi_text}\n\n"
        end

        amc.julie_action.text = "#{say_hi_text}#{text_template}"

      elsif amc.julie_action.action_nature == JulieAction::JD_ACTION_WAIT_FOR_CONTACT
        text_template = get_wait_for_contact_template({
                                                          locale: interpretation[:locale]
                                                      })
        amc.julie_action.text = text_template
      elsif amc.julie_action.action_nature == JulieAction::JD_ACTION_NOTHING_TO_DO
        # No text to write
      elsif amc.julie_action.action_nature == JulieAction::JD_ACTION_FORWARD_TO_SUPPORT
        text_template = get_forward_to_support_template({
                                                            locale: interpretation[:locale]
                                                        })
        amc.julie_action.text = text_template
      elsif amc.julie_action.action_nature == JulieAction::JD_ACTION_FORWARD_TO_CLIENT
        text_template = get_forward_to_client_template({
                                                           locale: interpretation[:locale]
                                                       })
        amc.julie_action.text = text_template
      end


      if params[:for_real]
        amc.operator = "julie@operator.juliedesk.com"
        m.message_classifications << amc
        message_hash = AutoMessageClassification.build_message(amc)
        EmailServer.deliver_message message_hash
      else
        m.auto_message_classification = amc
      end

      result[:auto_message_classification] = amc
      result[:status] = 'success'
    else
      result[:status] = 'error'
    end

    result
  end

  def self.build_message message_classification
    m = message_classification.message
    m.messages_thread.re_import
    m = m.messages_thread.messages.find{|me| me.id == m.id}

    julie_alias = m.messages_thread.julie_alias
    footer_and_signature = julie_alias.generate_footer_and_signature(message_classification.locale)

    contact_emails = MessagesThread.contacts({server_messages_to_look: [m.server_message]}).map { |c| c[:email].try(:downcase) }
    present_attendees = JSON.parse(message_classification.attendees).select{|a| a['isPresent'] == 'true'}
    initial_recipients_only_reply_all = m.initial_recipients({
                                                                 only_reply_all: true,
                                                                 contact_emails: contact_emails,
                                                                 present_attendees: present_attendees
                                                             })
    initial_recipients = m.initial_recipients({
                                                  contact_emails: contact_emails,
                                                  present_attendees: present_attendees
                                              })

    should_quote = ((initial_recipients[:to] + initial_recipients[:cc]) - initial_recipients_only_reply_all[:to] - initial_recipients_only_reply_all[:cc]).length == 0
    text_in_email = "#{message_classification.julie_action.text}#{footer_and_signature[:text_footer]}"

    recipients_to = initial_recipients[:to]
    recipients_cc = initial_recipients[:cc]
    if message_classification.classification == AutoMessageClassification::WAIT_FOR_CONTACT
      recipients_to = [initial_recipients[:client]]
      recipients_cc = []
    end

    {
        subject: m.messages_thread.subject,
        from: julie_alias.generate_from,
        to: recipients_to.join(", "),
        cc: recipients_cc.join(", "),
        html: text_to_html(text_in_email) + footer_and_signature[:html_signature].html_safe,
        quote_replied_message: should_quote,
        quote_forward_message: false,
        reply_to_message_id: m.server_message_id
    }

  end

  def mock_julie_message original_server_message={}

    if self.classification == AutoMessageClassification::NOTHING_TO_DO
      oag = OperatorActionsGroup.new({
                                         initiated_at: self.created_at,
                                         label: OperatorActionsGroup::LABEL_ARCHIVE,
                                         duration: 20 + (self.id % 9),
                                         target_id: self.julie_action.id,
                                         target_type: JulieAction.to_s
                                     })

      return oag
    end

    m = self.message
    m.messages_thread.re_import
    m = m.messages_thread.messages.find{|me| me.id == m.id}

    julie_alias = m.messages_thread.julie_alias
    footer_and_signature = julie_alias.generate_footer_and_signature(self.locale)

    contact_emails = MessagesThread.contacts({server_messages_to_look: [m.server_message]}).map { |c| c[:email].try(:downcase) }
    present_attendees = JSON.parse(self.attendees).select{|a| a['isPresent'] == true}
    initial_recipients_only_reply_all = m.initial_recipients({
                                                                 only_reply_all: true,
                                                                 contact_emails: contact_emails,
                                                                 present_attendees: present_attendees
                                                             })
    initial_recipients = m.initial_recipients({
                                                  contact_emails: contact_emails,
                                                  present_attendees: present_attendees
                                              })

    should_quote = ((initial_recipients[:to] + initial_recipients[:cc]) - initial_recipients_only_reply_all[:to] - initial_recipients_only_reply_all[:cc]).length == 0

    if self.from_ai
      text_in_email = "#{self.julie_action.text}#{footer_and_signature[:text_footer]}"
    else
      text_in_email = "#{self.julie_action.text}"
    end

    recipients_to = initial_recipients[:to]
    recipients_cc = initial_recipients[:cc]
    if self.classification == AutoMessageClassification::WAIT_FOR_CONTACT
      recipients_to = [initial_recipients[:client]]
      recipients_cc = []
    end

    m = Message.new({
                    from_me: true,
                    server_message: {
                        "from" => julie_alias.generate_from,
                        "to" => recipients_to.join(", "),
                        "cc" => recipients_cc.join(", "),
                        "labels" => "",
                        "snippet" => "#{"#{self.julie_action.text}".first(30)}...",
                        "parsed_html" => text_to_html(text_in_email) + footer_and_signature[:html_signature].html_safe + (should_quote ? "<blockquote>#{original_server_message['parsed_html']}</blockquote>" : "").html_safe,
                        'date' => (self.message.received_at + (3 * 60 + self.id % (5 * 60)).seconds).to_s,

                    },
                    messages_thread: self.message.messages_thread
                })
    m.instance_variable_set(:@auto_message_classification_id, self.id)
    m
  end
end
