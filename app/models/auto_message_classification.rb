class AutoMessageClassification < MessageClassification

  include ApplicationHelper
  extend ApplicationHelper
  extend TemplateGeneratorHelper
  has_many :auto_message_classification_reviews

  self.table_name = "auto_message_classifications"

  def notation operator_id
    auto_message_classification_reviews.find{|amcr| "#{amcr.operator_id}" == "#{operator_id}" }.try(:notation)
  end

  def notation_comments operator_id
    auto_message_classification_reviews.find{|amcr| "#{amcr.operator_id}" == "#{operator_id}"}.try(:comments)
  end

  def self.build_from_operator message_id, params={}
    m = Message.find(message_id)

    mc = m.message_classifications.select{|mc| mc.julie_action.done}.first
    ja = mc.julie_action.dup
    amc = AutoMessageClassification.new(mc.dup.attributes)
    amc.julie_action = ja
    amc.from_ai = false

    m.auto_message_classification = amc
  end

  def self.build_from_conscience message_id, params={}
    # Get objects
    m = Message.find(message_id)
    m.messages_thread.re_import
    processing_date = m.received_at + 5.minutes
    m = m.messages_thread.messages.find{|me| me.id == m.id}
    account = m.messages_thread.account


    # Get interpretations
    main_message_interpretation = m.message_interpretations.find{|mi| mi.question == "main"}
    entities_interpretation = m.message_interpretations.find{|mi| mi.question == "entities"}
    if params[:force_reinterpretation]
      main_message_interpretation.process
      entities_interpretation.process
    end
    main_interpretation = JSON.parse(main_message_interpretation.raw_response)

    # Get duration (should be done at conscience level in the future)
    found_duration = nil
    duration_entities = Nokogiri::HTML(JSON.parse(entities_interpretation.raw_response)['annotated']).css(".juliedesk-entity.duration")
    if duration_entities.length == 1
      duration_string = duration_entities.first.attr('value')

      if (md = /.{2}(\d*)M/.match(duration_string))
        found_duration = md[1].to_i
      elsif (md = /.{2}(\d*)H/.match(duration_string))
        found_duration = md[1].to_i * 60
      end
    end


    # Build interpretation hash in backoffice format
    interpretation = {
        :classification => main_interpretation["request_classif"] || main_interpretation["raw_request_classif"],
        :appointment => main_interpretation['appointment_classif'] || main_interpretation['raw_appointment_classif'],
        :locale => main_interpretation["language_detected"],
        :entities => {},
        attendees: MessagesThread.contacts({server_messages_to_look: [m.server_message]}).map do |att|
          human_civilities_response = AiProxy.new.build_request(:parse_human_civilities, { fullname: att[:name], at: att[:email]})
          company_response = AiProxy.new.build_request(:get_company_name, { address: "severin.naudet@wework.com", message: "" })
          {
              'email' => att[:email],
              'fullName' => att[:name],
              'firstName' => human_civilities_response['first_name'],
              'lastName' => human_civilities_response['last_name'],
              'company' => company_response['company'],
              'usageName' => human_civilities_response['first_name'],
              'isPresent' => true
          }
        end,
        constraints_data: main_interpretation['constraints_data']
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

      amc.assign_attributes({
                                appointment_nature: interpretation[:appointment],
                                summary: nil,
                                location:  appointment['default_address'].try(:[], 'address'),
                                attendees: AutoMessageClassification.clean_and_categorize_clients(interpretation[:attendees]).to_json,
                                notes: nil,
                                date_times: "[]",
                                locale: interpretation[:locale],
                                timezone: client_preferences[:timezone],
                                constraints_data: (interpretation[:constraints_data] || []).to_json,
                                duration: found_duration || appointment['duration'],
                                call_instructions: {
                                    target: target,
                                    support: "mobile",
                                    targetInfos: {}
                                }.to_json
                            })

    end

    amc.julie_action = JulieAction.new({
                                           action_nature: amc.computed_julie_action_nature,
                                           done: true,
                                           server_message_id: m.server_message_id,
                                       })


    if amc.julie_action.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES

      # Handle calendar
      date_suggestions_response = AiProxy.new.build_request(:fetch_dates_suggestions, {
          account_email: account.email,
          thread_data: m.messages_thread.computed_data([amc]),
          raw_constraints: interpretation[:constraints_data],
          n_suggested_dates: 4,
          attendees: [],
          message_id: m.id,
          date: processing_date.strftime("%Y-%m-%d")
      })
      date_suggestions = date_suggestions_response["suggested_dates"]
      amc.date_times = (date_suggestions || []).to_json

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
      amc.operator_id = Operator.find_by_email("julie@operator.juliedesk.com").try(:id)
      m.message_classifications << amc
      message_hash = AutoMessageClassification.build_message(amc)
      EmailServer.deliver_message message_hash
    else
      m.auto_message_classification = amc
    end

    amc
  end

  def self.build_message message_classification
    julie_alias = message_classification.message.messages_thread.julie_alias
    footer_and_signature = julie_alias.generate_footer_and_signature(message_classification.locale)

    initial_recipients_only_reply_all = message_classification.message.initial_recipients only_reply_all: true
    initial_recipients = message_classification.message.initial_recipients

    should_quote = ((initial_recipients[:to] + initial_recipients[:cc]) - initial_recipients_only_reply_all[:to] - initial_recipients_only_reply_all[:cc]).length == 0
    text_in_email = "#{message_classification.julie_action.text}#{footer_and_signature[:text_footer]}"

    recipients_to = initial_recipients[:to]
    recipients_cc = initial_recipients[:cc]
    if message_classification.classification == AutoMessageClassification::WAIT_FOR_CONTACT
      recipients_to = [initial_recipients[:client]]
      recipients_cc = []
    end

    {
        subject: message_classification.message.messages_thread.subject,
        from: julie_alias.generate_from,
        to: recipients_to.join(", "),
        cc: recipients_cc.join(", "),
        html: text_to_html(text_in_email) + footer_and_signature[:html_signature].html_safe,
        quote_replied_message: should_quote,
        quote_forward_message: false,
        reply_to_message_id: message_classification.message.server_message_id
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

    julie_alias = self.message.messages_thread.julie_alias
    footer_and_signature = julie_alias.generate_footer_and_signature(self.locale)

    initial_recipients_only_reply_all = self.message.initial_recipients only_reply_all: true
    initial_recipients = self.message.initial_recipients

    should_quote = ((initial_recipients[:to] + initial_recipients[:cc]) - initial_recipients_only_reply_all[:to] - initial_recipients_only_reply_all[:cc]).length == 0

    if self.from_ai
      text_in_email = "#{self.julie_action.text}#{footer_and_signature[:text_footer]}"
    else
      text_in_email = "#{self.julie_action.text}"
    end

    recipients_to = initial_recipients[:to].join(", ")
    recipients_cc = initial_recipients[:cc].join(", ")
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
