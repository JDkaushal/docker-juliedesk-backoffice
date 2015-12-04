class Message < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include ERB::Util

  belongs_to :messages_thread
  has_many :message_classifications

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
    # Get server threads in inbox
    server_threads = EmailServer.list_messages_threads(filter: "INBOX", limit: 100, full: true)

    # Put by default all previous messages_thread out of inbox
    MessagesThread.update_all(in_inbox: false)

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
        should_update_thread = (messages_thread.server_version != server_thread['version'] || messages_thread.account_email.nil?)
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
            messages_thread.messages.create server_message_id: server_message['id'],
                                            received_at: DateTime.parse(server_message['date']),
                                            reply_all_recipients: Message.generate_reply_all_recipients(server_message).to_json,
                                            from_me: server_message['from_me']

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

  def self.expand_parts parts
    parts.map{|part|
      if part['mimeType'].include? "multipart"
        self.expand_parts part['parts']
      else
        part
      end
    }.flatten
  end

  def self.format_email_body message
    message.server_message['parsed_html']
  end
end