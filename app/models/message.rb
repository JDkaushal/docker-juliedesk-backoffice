class Message < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include ERB::Util

  belongs_to :messages_thread
  has_many :message_classifications
  has_many :message_interpretations

  attr_accessor :server_message


  def get_reply_all_recipients_emails
    recipients = JSON.parse(self.reply_all_recipients)

    recipients["to"].map{|r| r["email"]} + recipients["cc"].map{|r| r["email"]}
  end

  def clean_delete
    self.message_classifications.each do |mc|
      mc.clean_delete
    end
    self.delete
  end


  def initial_recipients params={}
    reply_all_recipients = JSON.parse(self.reply_all_recipients || "{}")

    initial_to_emails = reply_all_recipients['to'].map{|c| c['email']}
    initial_cc_emails = reply_all_recipients['cc'].map{|c| c['email']}

    contact_emails = self.messages_thread.contacts(with_client: true).map { |c| c[:email] }
    attendee_emails = self.messages_thread.computed_data[:attendees].select{|a| a['isPresent'] == 'true' }.map{|a| a['email']}

    all_client_emails = self.messages_thread.account.all_emails
    client_email = ((initial_to_emails + initial_cc_emails + attendee_emails) & all_client_emails).first || self.messages_thread.client_email

    possible_emails = (initial_to_emails +
        initial_cc_emails +
        attendee_emails +
        contact_emails +
        [client_email]).uniq


    possible_emails += (self.messages_thread.julie_aliases || []).map(&:email)
    possible_emails.reject! { |c| c.blank? }

    if params[:only_reply_all]
      computed_initial_to_emails = initial_to_emails.uniq
      computed_initial_cc_emails = initial_cc_emails.uniq

      unless (computed_initial_to_emails + computed_initial_cc_emails).include? client_email
        if computed_initial_to_emails.empty?
          computed_initial_to_emails += [client_email]
        else
          computed_initial_cc_emails += [client_email]
        end
      end

      {
          to: computed_initial_to_emails.sort,
          cc: computed_initial_cc_emails.sort,
          client: client_email,
          possible: possible_emails.sort
      }
    else
      # Need to reject empty string because there can be some if the operator enter an email then don't suppress it appropriately
      computed_initial_to_emails = (attendee_emails.uniq - all_client_emails).reject { |c| c.blank? }
      computed_initial_cc_emails = ((initial_to_emails + initial_cc_emails).uniq - computed_initial_to_emails - all_client_emails).reject { |c| c.blank? }

      if computed_initial_to_emails.empty?
        result = {
            to: [client_email].sort.map(&:downcase),
            cc: computed_initial_cc_emails.sort.map(&:downcase),
            client: client_email,
            possible: possible_emails.sort
        }
      else
        result = {
            to: computed_initial_to_emails.sort.map(&:downcase),
            cc: (computed_initial_cc_emails + [client_email]).sort.map(&:downcase),
            client: client_email,
            possible: possible_emails.sort
        }
      end

      result[:cc] -= result[:to]
      result[:possible] = result[:possible].map(&:downcase).uniq
      result
    end


  end

  def from_me?
      server_message['from_me']
  end

  def generator_operator_actions_group operator_actions_groups
    return nil if self.generator_message_classification.nil?
    @generator_operator_actions_group ||= if operator_actions_groups

      operator_actions_groups.select{|operator_actions_group|
        operator_actions_group.is_action? &&
            operator_actions_group.target_id == self.generator_message_classification.julie_action.id
      }.first
                                          else
                                            nil
                                          end
  end

  def generator_message_classification
    messages_thread.messages.map(&:message_classifications).flatten.map(&:julie_action).select{|ja|
      ja.server_message_id && ja.server_message_id == self.server_message_id
    }.first.try(:message_classification)
  end

  def julie_alias
    Message.julie_aliases_from_server_message(self.server_message).first
  end

  def self.julie_aliases_from_server_message server_message, params={}
    (params[:julie_aliases] || JulieAlias.all).select{|julie_alias|
      "#{server_message['to']} #{server_message['cc']}".downcase.include? julie_alias.email
    }
  end

  def destined_to_julie? params={}
    (params[:julie_aliases] || JulieAlias.all).select{|julie_alias|
      "#{server_message['to']}".downcase.include? julie_alias.email
    }.any?
  end

  def is_discussion_client_julie_only
    result = false
    if destined_to_julie?
      # If the message is destined to Julie only
      message_tos = server_message['to'].split(',');
      result = message_tos.size == 1 && (server_message['cc'].blank? ||  server_message['cc'].split(',').size == 0) && ApplicationHelper.find_addresses(server_message['from']).addresses.first.address == messages_thread.account_email
    end
    result
  end

  def self.import_emails

    # Get server threads in inbox, only versions (quick call)
    server_threads = EmailServer.list_messages_threads(filter: "INBOX", limit: 1000, only_version: true)
    inbox_server_thread_ids = server_threads.map{|st| st['id']}
    inbox_messages_threads = MessagesThread.where(server_thread_id: inbox_server_thread_ids)

    #First, remove from inbox all messages_thread that should not be in inbox anymore
    MessagesThread.where(in_inbox: true).where.not(server_thread_id: inbox_server_thread_ids).update_all(in_inbox: false)
    #Then, put in inbox the others
    MessagesThread.where(in_inbox: false).where(server_thread_id: inbox_server_thread_ids).update_all(in_inbox: true)

    server_thread_ids_to_update = []
    server_thread_ids_to_create = []

    server_threads.each do |server_thread|
      messages_thread = inbox_messages_threads.select{|mt| mt.server_thread_id == server_thread['id']}.first
      if messages_thread
        if "#{messages_thread.server_version}" == "#{server_thread['version']}"
          # Nothing to do
        else
          server_thread_ids_to_update << server_thread['id']
        end
      else
        server_thread_ids_to_create << server_thread['id']
      end
    end

    if (server_thread_ids_to_update + server_thread_ids_to_create).empty?
      return []
    end

    server_threads = EmailServer.list_messages_threads(specific_ids: server_thread_ids_to_update + server_thread_ids_to_create, limit: 1000, full: true)

    # Julie aliases in cache
    julie_aliases = JulieAlias.all
    # Accounts in cache (light mode)
    accounts_cache = Account.accounts_cache(mode: "light")

    # Store the messages_thread_ids that will be updated by this method
    updated_messages_thread_ids = []


    server_threads.each do |server_thread|
      should_update_thread = true


      messages_thread = MessagesThread.find_by_server_thread_id server_thread['id']
      if messages_thread
        should_update_thread = ("#{messages_thread.server_version}" != "#{server_thread['version']}" || messages_thread.account_email.nil?)
        messages_thread.update_attributes({in_inbox: true, server_version: server_thread['version']})
      end

      if should_update_thread

        if messages_thread
          if messages_thread.account_email == nil
            account_email = MessagesThread.find_account_email(server_thread, {accounts_cache: accounts_cache})
            account = Account.create_from_email(account_email, {accounts_cache: accounts_cache})
            messages_thread.update_attributes({
                                                  account_email: account_email,
                                                  account_name: account.try(:usage_name)
                                              })
          end
        else
          account_email = MessagesThread.find_account_email(server_thread, {accounts_cache: accounts_cache})
          account = Account.create_from_email(account_email, {accounts_cache: accounts_cache})
          messages_thread = MessagesThread.create server_thread_id: server_thread['id'], in_inbox: true, account_email: account_email, account_name: account.try(:usage_name)

          if MessagesThread.several_accounts_detected(server_thread, {accounts_cache: accounts_cache})
            messages_thread.delegate_to_support
          end
        end

        messages_thread.update_attributes({subject: server_thread['subject'], snippet: server_thread['snippet']})

        server_thread['messages'].each do |server_message|
          message = Message.find_by_server_message_id server_message['id']

          unless message
            m = messages_thread.messages.create server_message_id: server_message['id'],
                                                received_at: DateTime.parse(server_message['date']),
                                                reply_all_recipients: Message.generate_reply_all_recipients(server_message).to_json,
                                                from_me: server_message['from_me']

            # Added by Nico to interprete
            unless m.from_me
              m.delay.interprete
            end

            updated_messages_thread_ids << messages_thread.id
          end
        end

        # Check if there are several julie aliases only if there was a new message
        if updated_messages_thread_ids.include? messages_thread.id && MessagesThread.julie_aliases_from_server_thread(server_thread, {julie_aliases: julie_aliases}).length > 1
          messages_thread.delegate_to_support
        end
      end
    end

    updated_messages_thread_ids.uniq
  end


  def self.generate_reply_all_recipients(server_message)
    from_addresses = ApplicationHelper.find_addresses(server_message['from']).addresses
    to_addresses = ApplicationHelper.find_addresses(server_message['to']).addresses
    {
        to: (from_addresses + to_addresses).uniq.select{|dest| !JulieAlias.all.map(&:email).include?(dest.address.try(:downcase))}.map{|dest|
          {
              email: dest.address,
              name: dest.name
          }
        },
        cc: ApplicationHelper.find_addresses(server_message['cc']).addresses.select{|dest| !JulieAlias.all.map(&:email).include?(dest.address.try(:downcase))}.map{|dest|
          {
              email: dest.address,
              name: dest.name
          }
        }
    }
  end

  def generate_threads julie_messages
    # Get from field

    self.messages_thread.re_import
    cache_server_message = self.messages_thread.messages.select{|m| m.id == self.id}.first.server_message

    julie_alias = self.messages_thread.julie_alias

    # Process each one of the messages we want to create
    julie_messages.each do |julie_message_hash|
      # Try to find an existing thread which would have resulted in the given event
      existing_message = JulieAction.where(event_id: julie_message_hash['event_id'], calendar_id: julie_message_hash['calendar_id']).first.try(:message_classification).try(:message)


      if existing_message.try(:messages_thread)
        copy_response = EmailServer.copy_message_to_existing_thread server_message_id: self.server_message_id, server_thread_id: existing_message.messages_thread.server_thread_id
        EmailServer.deliver_message({
                                        subject: julie_message_hash['subject'],
                                        from: julie_alias.generate_from,
                                        to: julie_alias.generate_from,
                                        text: "#{strip_tags(julie_message_hash['html'])}\n\n\n\nPrevious messages:\n\n#{cache_server_message['text']}",
                                        html: julie_message_hash['html'] + "<br><br><br><br>Previous message:<br><br>" + cache_server_message['parsed_html'],
                                        quote: false,
                                        reply_to_message_id:  copy_response['id']
                                    })
      else
        copy_response = EmailServer.copy_message_to_new_thread server_message_id: self.server_message_id, force_subject: julie_message_hash['subject']
        server_message = EmailServer.deliver_message({
                                        subject: julie_message_hash['subject'],
                                        from: julie_alias.generate_from,
                                        to: julie_alias.generate_from,
                                        text: "#{strip_tags(julie_message_hash['html'])}\n\n\n\nPrevious messages:\n\n#{cache_server_message['text']}",
                                        html: julie_message_hash['html'] + "<br><br><br><br>Previous message:<br><br>" + cache_server_message['parsed_html'],
                                        quote: false,
                                        reply_to_message_id: copy_response['id']
                                    })

        Message.associate_event_data server_message,
                                                {
                                                    'id' => julie_message_hash['event_id'],
                                                    'calendar_id' => julie_message_hash['calendar_id'],
                                                    'url' => julie_message_hash['event_url'],
                                                    'calendar_login_username' => julie_message_hash['calendar_login_username'],
                                                    'attendees' => julie_message_hash['attendees'],
                                                    'summary' => julie_message_hash['summary'],
                                                    'location' => julie_message_hash['location'],
                                                    'duration' => julie_message_hash['duration'],
                                                    'notes' => julie_message_hash['notes'],
                                                },
                                                self.messages_thread
      end
    end
  end

  def self.associate_event_data server_message, event, original_messages_thread
    # Create the message_thread in DB
    messages_thread = MessagesThread.create server_thread_id: server_message['messages_thread_id'],
                                            in_inbox: true,
                                            account_email: original_messages_thread.account_email,
                                            account_name: original_messages_thread.account_name,
                                            subject: server_message['subject'],
                                            snippet: server_message['snippet']

    # Create the message in DB
    message = messages_thread.messages.create server_message_id: server_message['id'],
                                              received_at: DateTime.parse(server_message['date']),
                                              reply_all_recipients: Message.generate_reply_all_recipients(server_message).to_json,
                                              from_me: server_message['from_me']

    attendees = (event['attendees'] || {}).select{|k, attendee|
      !original_messages_thread.account.all_emails.include? attendee['email']
    }.map{|k, attendee|
      {
        k => {
            email: attendee['email'],
            name: "#{attendee['displayName']}"
        }
      }
    }.reduce(:merge)
    # Create the message_classification in DB
    message_classification = message.message_classifications.create_from_params locale: original_messages_thread.computed_data[:locale],
                                                                                classification: MessageClassification::ASK_AVAILABILITIES,
                                                                                operator: original_messages_thread.julie_alias.email,
                                                                                attendees: attendees,
                                                                                processed_in: 0,
                                                                                summary: event['summary'],
                                                                                duration: event['duration'],
                                                                                location: event['location'],
                                                                                notes: event['notes']


    # Create the julie_action in DB to finally store event data
    message_classification.julie_action.update_attributes done: true,
                                                          event_id: event['id'],
                                                          calendar_id: event['calendar_id'],
                                                          event_url: event['url'],
                                                          calendar_login_username: event['calendar_login_username']

    messages_thread.id
  end

  def classification_category_for_classification classification
    messages_thread.classification_category_for_classification(classification)
  end

  def interprete
    if self.message_interpretations.empty?
      MessageInterpretation.questions.each do |question|
        self.message_interpretations << MessageInterpretation.new(question: question)
      end

      self.message_interpretations.each do |message_interpretation|
        message_interpretation.process
      end
    end
  end

  def interpretations
    main_answer = begin
      JSON.parse(self.message_interpretations.select{|mi| mi.question == MessageInterpretation::QUESTION_MAIN}.first.try(:raw_response) || "{}")
    rescue
      {}
    end
    entities_answer = begin
      JSON.parse(self.message_interpretations.select{|mi| mi.question == MessageInterpretation::QUESTION_ENTITIES}.first.try(:raw_response) || "{}")
    rescue
      {}
    end
    {
        classification: main_answer['request_classif'],
        appointment: main_answer['appointment_classif'],
        locale: main_answer['language_detected'],
        entities: {
            phone_numbers: (entities_answer['annotated'] || "").match(/<ENTITY_type=PHONE>(.*)<\/ENTITY>/).try(:captures) || []
        }
    }
  end

  def self.expand_parts parts
    parts.map{|part|
      if part['mimeType'].include? "multipart"
        self.expand_parts part['parts']
        self.expand_parts part['parts']
      else
        part
      end
    }.flatten
  end

  def self.format_email_body message
    body = message.server_message['parsed_html']
    message.interpretations[:entities][:phone_numbers].each do |phone_number|
        body.gsub!(Regexp.new("(#{Regexp.quote(phone_number)})"), '<span class="juliedesk-phone-number">\1</span>')
    end
    body
  end

  def self.parallel_run_stats data=nil
    data ||= self.parallel_run_recap

    fields = data.first[:human].keys

    Hash[fields.map do |field|
      support = data.length
      total_number = data.select{|d| %w"correct incorrect".include? d[:comparison][field]}.length
      precision = total_number > 0 ? data.select{|d| d[:comparison][field] == "correct"}.length * 1.0 / total_number : nil
      recall = total_number * 1.0 / support
      [field, {
          precision: precision,
          recall: recall,
          support: support
      }]
    end]
  end

  def self.parallel_run_recap
    message_interpretations = MessageInterpretation.where(question: MessageInterpretation::QUESTION_MAIN).select(:message_id, :raw_response, :question)

    message_ids = message_interpretations.map(&:message_id).uniq

    message_classifications = MessageClassification.where(message_id: message_ids).select(:message_id, :classification, :updated_at, :appointment_nature, :locale)

    messages = Message.select(:id, :messages_thread_id).where(id: message_ids)

    data = message_ids.map do |message_id|
      mc = message_classifications.select{|mc| mc.message_id == message_id}.sort_by(&:updated_at).last
      message_interpretation = message_interpretations.select{|mc| mc.message_id == message_id}.last

      if mc && message_interpretation.raw_response
        ai_response = JSON.parse(message_interpretation.raw_response)
        {
            message_id: message_id,
            messages_thread_id: messages.select{|m| m.id == message_id}.first.messages_thread_id,
            ai: {
                classification: ai_response['request_classif'],
                appointment: ai_response['appointment_classif'],
                locale: ai_response['language_detected'],
            },
            human: {
                classification: mc.classification,
                appointment: mc.appointment_nature,
                locale: mc.locale
            },
        }
      else
        nil
      end
    end.compact

    data.map do |d|
      classification_correct = if d[:ai][:classification] != "unknown"
                                 if d[:ai][:classification] == d[:human][:classification]
                                 "correct"
                                 else
                                  "incorrect"
                                 end
                               else
                                 "unknown"
                               end
      appointment_correct = if d[:human][:appointment]
                              if d[:ai][:appointment] == d[:human][:appointment]
                                "correct"
                              else
                                "incorrect"
                              end
                            else
                              "unknown"
                            end

      locale_correct = appointment_correct = if d[:human][:locale]
                                               if d[:ai][:locale] == d[:human][:locale]
                                                 "correct"
                                               else
                                                 "incorrect"
                                               end
                                             else
                                               "unknown"
                                             end

      d.merge({
                  comparison: {
                      classification: classification_correct,
                      appointment: appointment_correct,
                      locale: locale_correct
                  }
              })
    end

  end
end