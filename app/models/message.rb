class Message < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include ERB::Util

  belongs_to :messages_thread
  has_many :message_classifications

  attr_writer :google_message

  def self.bugged
    [] + nil
  end

  def clean_delete
    self.message_classifications.each do |mc|
      mc.clean_delete
    end
    self.delete
  end

  def correct_google_message
    Message.correct_google_message @google_message
  end

  def self.correct_google_message google_message
    m = Message.new

    google_message.text ||= google_message.body || m.strip_tags(google_message.html)
    google_message.html ||= m.send(:h, m.simple_format(google_message.text))

    google_message.body = nil
    google_message
  end

  def google_message
    unless @google_message
      @google_message = Gmail::Message.get self.google_message_id

      correct_google_message
    end

    @google_message
  end


  def initial_recipients params={}
    reply_all_recipients = JSON.parse(self.reply_all_recipients || "{}")
    initial_to_emails = reply_all_recipients['to'].map{|c| c['email']}
    initial_cc_emails = reply_all_recipients['cc'].map{|c| c['email']}

    contact_emails = self.messages_thread.contacts(with_client: true).map { |c| c[:email] }
    attendee_emails = self.messages_thread.computed_data[:attendees].map{|a| a['email']}


    all_client_emails = self.messages_thread.account.all_emails
    client_email = ((initial_to_emails + initial_cc_emails + attendee_emails) & all_client_emails).first || self.messages_thread.client_email

    possible_emails = (initial_to_emails +
        initial_cc_emails +
        attendee_emails +
        contact_emails +
        [client_email]).uniq





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
      computed_initial_to_emails = attendee_emails.uniq - all_client_emails
      computed_initial_cc_emails = (initial_to_emails + initial_cc_emails).uniq - computed_initial_to_emails - all_client_emails

      if computed_initial_to_emails.empty?
        {
            to: [client_email].sort,
            cc: computed_initial_cc_emails.sort,
            client: client_email,
            possible: possible_emails.sort
        }
      else
        {
            to: computed_initial_to_emails.sort,
            cc: (computed_initial_cc_emails + [client_email]).sort,
            client: client_email,
            possible: possible_emails.sort
        }
      end
    end


  end

  def from_me?
    JulieAlias.all.select{|julie_alias|
      google_message.from.downcase.include? julie_alias.email
    }.length > 0
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
      ja.google_message_id && ja.google_message_id == self.google_message_id
    }.first.try(:message_classification)
  end

  def julie_alias
    Message.julie_aliases_from_google_message(self.google_message).first
  end

  def self.julie_aliases_from_google_message google_message, params={}
    (params[:julie_aliases] || JulieAlias.all).select{|julie_alias|
      "#{google_message.to} #{google_message.cc}".downcase.include? julie_alias.email
    }
  end

  def self.import_emails
    # Get google threads in inbox
    google_threads = Gmail::Label.inbox.threads

    # Put by default all previous messages_thread out of inbox
    MessagesThread.update_all(in_inbox: false)

    # Julie aliases in cache
    julie_aliases = JulieAlias.all

    updated_messages_thread_ids = []


    google_threads.each do |google_thread|
      should_update_thread = true

      messages_thread = MessagesThread.find_by_google_thread_id google_thread.id
      if messages_thread
        should_update_thread = (messages_thread.google_history_id != google_thread.historyId || messages_thread.account_email.nil?)
        messages_thread.update_attributes({in_inbox: true, google_history_id: google_thread.historyId})
      end

      if should_update_thread
        google_thread = google_thread.detailed

        if messages_thread
          if messages_thread.account_email == nil
            account_email = MessagesThread.find_account_email(google_thread)
            messages_thread.update_attributes({
                                                  account_email: account_email,
                                                  account_name: Account.create_from_email(account_email).try(:usage_name)
                                              })
          end
        else
          account_email = MessagesThread.find_account_email(google_thread)
          messages_thread = MessagesThread.create google_thread_id: google_thread.id, in_inbox: true, account_email: account_email, account_name: Account.create_from_email(account_email).try(:usage_name)
          if account_email.nil?
            messages_thread.warn_support
          end

          if MessagesThread.several_accounts_detected(google_thread)
            messages_thread.delegate_to_support
          end
        end

        sorted_messages = google_thread.messages.sort_by{|m| DateTime.parse(m.date)}

        snippet = sorted_messages.last.snippet
        messages_thread.update_attributes({subject: sorted_messages.first.subject, snippet: snippet})

        google_thread.messages.each do |google_message|
          google_message = Message.correct_google_message google_message
          message = Message.find_by_google_message_id google_message.id

          unless message
            messages_thread.messages.create google_message_id: google_message.id,
                                            received_at: DateTime.parse(google_message.date),
                                            reply_all_recipients: Message.generate_reply_all_recipients(google_message).to_json,
                                            from_me: google_message.labelIds.include?("SENT")

            updated_messages_thread_ids << messages_thread.id
          end
        end

        # Check if there are several julie aliases only if there was a new message
        if updated_messages_thread_ids.include? messages_thread.id && MessagesThread.julie_aliases_from_google_thread(google_thread, {julie_aliases: julie_aliases}).length > 1
          messages_thread.delegate_to_support
        end
      end
    end

    updated_messages_thread_ids.uniq
  end


  def self.generate_reply_all_recipients(google_message)

    gm = Message.correct_google_message(google_message).reply_all_with(Gmail::Message.new(text: "", html: ""))
    {


        to: ApplicationHelper.find_addresses(gm.to).addresses.select{|dest| !JulieAlias.all.map(&:email).include?(dest.address.try(:downcase))}.map{|dest|
          {
              email: dest.address,
              name: dest.name
          }
        },
        cc: ApplicationHelper.find_addresses(gm.cc).addresses.select{|dest| !JulieAlias.all.map(&:email).include?(dest.address.try(:downcase))}.map{|dest|
          {
              email: dest.address,
              name: dest.name
          }
        }
    }
  end

  def generate_threads julie_messages

    # Get from field
    julie_alias = self.messages_thread.julie_alias
    from = julie_alias.generate_from

    updated_messages_thread_ids = []
    # Process each one of the messages we want to create
    julie_messages.each do |julie_message_hash|

      # Try to find an existing thread which would have resulted in the given event
      existing_message = JulieAction.where(event_id: julie_message_hash['event_id'], calendar_id: julie_message_hash['calendar_id']).first.try(:message_classification).try(:message)

      if existing_message.try(:messages_thread)
        # Copy the original message into the existing thread
        self.google_message.threadId = existing_message.messages_thread.google_thread_id
        self.google_message.subject = existing_message.google_message.subject
        self.google_message.labelIds = (self.google_message.labelIds.select{|label| label != "SENT"} + ["INBOX"]).uniq
        updated_google_message = self.google_message.insert
      else
        # Copy the original message with a new subject and get the corresponding threadId
        self.google_message.threadId = nil
        self.google_message.subject = julie_message_hash['subject']
        self.google_message.labelIds = (self.google_message.labelIds.select{|label| label != "SENT"} + ["INBOX"]).uniq
        updated_google_message = self.google_message.insert
      end

      # Create the fake Julie's message
      julie_google_message = updated_google_message.reply_all_with(Gmail::Message.new({
                                                                                   text: "#{strip_tags(julie_message_hash['html'])}",
                                                                                   html: julie_message_hash['html']
                                                                               }))
      julie_google_message.to = from
      julie_google_message.from = from
      julie_google_message.cc = ""
      julie_google_message.insert



      if existing_message.try(:messages_thread)
        # Just update the message thread to notice it's in the inbox
        existing_message.messages_thread.update_attribute(:in_inbox, true)
        updated_messages_thread_ids << existing_message.messages_thread_id
      else
        # Now creating DB entries to associate the created thread with event data
        messages_thread_id = Message.associate_event_data updated_google_message,
                                     {
                                         'id' => julie_message_hash['event_id'],
                                         'calendar_id' => julie_message_hash['calendar_id'],
                                         'attendees' => julie_message_hash['attendees'],
                                         'summary' => julie_message_hash['summary'],
                                         'location' => julie_message_hash['location'],
                                         'duration' => julie_message_hash['duration'],
                                         'notes' => julie_message_hash['notes'],
                                     },
                                     self.messages_thread

        updated_messages_thread_ids << messages_thread_id
      end

      # Send new email notification
      Pusher.trigger('private-global-chat', 'new-email', {
          :message => 'new_email',
          :messages_threads_count => MessagesThread.items_to_classify_count,
          :updated_messages_thread_ids => updated_messages_thread_ids.uniq
      })
    end
  end

  def self.associate_event_data google_message, event, original_messages_thread
    # Create the message_thread in DB
    messages_thread = MessagesThread.create google_thread_id: google_message.threadId,
                                            in_inbox: true,
                                            account_email: original_messages_thread.account_email,
                                            account_name: original_messages_thread.account_name,
                                            subject: google_message.subject,
                                            snippet: google_message.snippet

    # Create the message in DB
    message = messages_thread.messages.create google_message_id: google_message.id,
                                              received_at: DateTime.parse(google_message.date),
                                              reply_all_recipients: Message.generate_reply_all_recipients(google_message).to_json,
                                              from_me: google_message.labelIds.include?("SENT")

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
                                                          calendar_id: event['calendar_id']

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
    email_body = message.google_message.html.gsub(/\<style\>.*?\<\/style\>/im, "").gsub(/\<script\>.*?\<\/script\>/im, "")
    n_body = Nokogiri::HTML(email_body)
    n_body.css('script').remove
    n_body.css('base').remove
    n_body.css("img").each do |img|
      begin
      src = img.attr("src")
      image_id = src.split("cid:")[1]
      all_parts = self.expand_parts(message.google_message['payload']['parts'])
      attachment = all_parts.select{|part| part['headers'].map{|h| h['value']}.include? "<#{image_id}>"}.first
      format = attachment.headers.select{|h| h['name'] == "Content-Type"}.first['value'].split(";").first
      attachment_id = attachment['body']['attachmentId']

      img["src"] = "/messages/#{message.id}/attachments/#{attachment_id}?format=#{format}"
      rescue
      end
    end
    n_body.to_s
  end
end