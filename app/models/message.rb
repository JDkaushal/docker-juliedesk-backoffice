class Message < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include ERB::Util

  belongs_to :messages_thread
  has_many :message_classifications

  attr_writer :google_message

  def self.bugged
    [] + nil
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

  def from_me?
    JULIE_ALIASES.select{|julie_alias|
      google_message.from.include? julie_alias
    }.length > 0
  end

  def julie_alias
    JULIE_ALIASES.select{|julie_alias|
       "#{google_message.to} #{google_message.cc}".include? julie_alias
    }.first
  end

  def self.import_emails
    # Get google threads in inbox
    google_threads = Gmail::Label.inbox.threads

    # Put by default all previous messages_thread out of inbox
    MessagesThread.update_all(in_inbox: false)


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
        end

        sorted_messages = google_thread.messages.sort_by{|m| DateTime.parse(m.date)}

        snippet = sorted_messages.last.snippet
        messages_thread.update_attributes({subject: sorted_messages.first.subject, snippet: snippet})

        google_thread.messages.each do |google_message|
          google_message = Message.correct_google_message google_message
          message = Message.find_by_google_message_id google_message.id

          unless message
            messages_thread.messages.create google_message_id: google_message.id, received_at: DateTime.parse(google_message.date), reply_all_recipients: Message.generate_reply_all_recipients(google_message).to_json
          end
        end
      end
    end

    nil
  end


  def self.generate_reply_all_recipients(google_message)

    gm = google_message.reply_all_with(Gmail::Message.new(text: "", html: ""))
    {

        to: Mail::AddressList.new("#{gm.to}".to_ascii).addresses.select{|dest| !JULIE_ALIASES.include?(dest.address)}.map{|dest|
          {
              email: dest.address,
              name: dest.name
          }
        },
        cc: Mail::AddressList.new("#{gm.cc}".to_ascii).addresses.select{|dest| !JULIE_ALIASES.include?(dest.address)}.map{|dest|
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
    from = "#{JULIE_ALIASES_DATA[julie_alias][:name]} <#{julie_alias}>"

    # Process each one of the messages we want to create
    julie_messages.each do |julie_message_hash|

      # Try to find an existing thread which would have resulted in the given event
      existing_message = JulieAction.where(event_id: julie_message_hash['event_id'], calendar_id: julie_message_hash['calendar_id']).first.try(:message_classification).try(:message)

      if existing_message.try(:messages_thread)
        # Copy the original message into the existing thread
        self.google_message.threadId = existing_message.messages_thread.google_thread_id
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
      else
        # Now creating DB entries to associate the created thread with event data
        Message.associate_event_data updated_google_message,
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

      end

      # Send new email notification
      Pusher.trigger('private-global-chat', 'new-email', {
          :message => 'new_email',
          :messages_threads_count => MessagesThread.items_to_classify_count
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
                                              reply_all_recipients: Message.generate_reply_all_recipients(google_message).to_json

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
                                                                                operator: original_messages_thread.julie_alias,
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
  end

  def classification_category_for_classification classification
    messages_thread.classification_category_for_classification(classification)
  end
end