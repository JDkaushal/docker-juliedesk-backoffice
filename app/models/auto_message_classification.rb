class AutoMessageClassification < MessageClassification

  include ApplicationHelper
  extend TemplateGeneratorHelper

  self.table_name = "auto_message_classifications"

  def self.build_from_operator message_id, params={}
    m = Message.find(message_id)

    mc = m.message_classifications.first
    ja = mc.julie_action.dup
    amc = AutoMessageClassification.new(mc.dup.attributes)
    amc.julie_action = ja
    amc.from_ai = false

    m.auto_message_classification = amc
  end

  def self.build_from_conscience message_id, params={}
    m = Message.find(message_id)
    previous_comments = m.auto_message_classification.try(:notation_comments)
    m.messages_thread.re_import

    processing_date = m.received_at + 5.minutes
    m = m.messages_thread.messages.find{|me| me.id == m.id}
    main_message_interpretation = m.message_interpretations.find{|mi| mi.question == "main"}
    entities_interpretation = m.message_interpretations.find{|mi| mi.question == "entities"}

    if params[:force_reinterpretation]
      main_message_interpretation.process
      entities_interpretation.process
    end

    account = m.messages_thread.account
    main_interpretation = JSON.parse(main_message_interpretation.raw_response)


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

    client_preferences = {
        timezone: account.default_timezone_id,
    }

    appointment = account.appointments.find{|appt| appt['label'] == interpretation[:appointment]}

    target = {
        "propose" => "client",
        "ask_interlocutor" => "interlocutor",
        "later" => "later"
    }[appointment["behaviour"]] || "later"

    amc = AutoMessageClassification.new({
                                            classification: interpretation[:classification],
                                            appointment_nature: interpretation[:appointment],
                                            summary: nil,
                                            location:  appointment['default_address'].try(:[], 'address'),
                                            attendees: AutoMessageClassification.clean_and_categorize_clients(interpretation[:attendees]).to_json,
                                            notes: nil,
                                            date_times: "[]",
                                            locale: interpretation[:locale],
                                            timezone: client_preferences[:timezone],
                                            constraints_data: interpretation[:constraints_data].to_json,
                                            duration: found_duration || appointment['duration'],
                                            notation_comments: previous_comments,
                                            call_instructions: {
                                                target: target,
                                                support: "mobile",
                                                targetInfos: {}
                                            }.to_json
                                        })

    amc.julie_action = JulieAction.new({
                                           action_nature: amc.computed_julie_action_nature,
                                           done: true,
                                           server_message_id: m.server_message_id,
                                       })

    if amc.julie_action.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES
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
      amc.date_times = date_suggestions.to_json

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

    end

    m.auto_message_classification = amc
  end

  def mock_julie_message original_server_message
julie_alias = self.message.messages_thread.julie_alias
    footer_and_signature = julie_alias.generate_footer_and_signature(self.locale)

    initial_recipients_only_reply_all = self.message.initial_recipients only_reply_all: true
    initial_recipients = self.message.initial_recipients

    should_quote = ((initial_recipients[:to] + initial_recipients[:cc]) - initial_recipients_only_reply_all[:to] - initial_recipients_only_reply_all[:cc]).length == 0

    m = Message.new({
                    from_me: true,
                    server_message: {
                        "from" => julie_alias.generate_from,
                        "to" => initial_recipients[:to].join(", "),
                        "cc" => initial_recipients[:cc].join(", "),
                        "labels" => "",
                        "snippet" => "#{self.julie_action.text.first(30)}...",
                        "parsed_html" => text_to_html("#{self.julie_action.text}#{footer_and_signature[:text_footer]}") + footer_and_signature[:html_signature].html_safe + (should_quote ? "<blockquote>#{original_server_message['parsed_html']}</blockquote>" : "").html_safe,
                        'date' => (self.message.received_at + (3 * 60 + self.id % (5 * 60)).seconds).to_s,

                    },
                    messages_thread: self.message.messages_thread
                })
    m.instance_variable_set(:@auto_message_classification_id, self.id)
    m
  end
end
