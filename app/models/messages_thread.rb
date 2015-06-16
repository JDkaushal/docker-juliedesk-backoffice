class MessagesThread < ActiveRecord::Base

  EVENT_SCHEDULED = "event_scheduled"
  SCHEDULING_EVENT = "scheduling_events"
  EVENTS_CREATED = "events_created"

  has_many :messages
  has_many :operator_actions, as: :target
  has_many :mt_operator_actions, class_name: OperatorAction

  belongs_to :locked_by_operator, foreign_key: "locked_by_operator_id", class_name: "Operator"


  def google_thread params={}
    if @google_thread.nil? || params[:force_refresh]
      @google_thread = Gmail::Thread.get(self.google_thread_id)
    end
    @google_thread
  end

  def account params={}
    @account ||= Account.create_from_email(account_email, params)
  end

  def delegate_to_support params={}
    self.update_attributes({
                               delegated_to_founders: true,
                               to_founders_message: params[:message]
                           })
    self.google_thread.modify(["Label_12"], [])

    self.warn_support params
  end

  def warn_support params={}
    gmail_message = Gmail::Message.new({text: "A new email thread has been delegated to support:\nhttps://juliedesk-backoffice.herokuapp.com/messages_threads/#{self.id}\n\nMessage: #{params[:message]}"})
    gmail_message.subject = "Email thread delegated to support"
    gmail_message.to = "guillaume@juliedesk.com"
    gmail_message.cc = "nicolas@juliedesk.com"
    gmail_message.from = "julie@juliedesk.com"
    gmail_message.deliver
  end

  def julie_alias
    messages.map(&:julie_alias).compact.uniq.first || JulieAlias.find_by_email("julie@juliedesk.com")
  end

  def contacts params = {}
    params[:google_messages_to_look] = google_thread.messages
    params[:forbidden_emails] = []
    unless params[:with_client]
      params[:forbidden_emails] = account.try(:all_emails) || []
    end
    MessagesThread.contacts params  end

  def self.contacts params = {}
    to_addresses = params[:google_messages_to_look].map{|m| Mail::AddressList.new((m.to || "").to_ascii).addresses}.flatten
    from_addresses = params[:google_messages_to_look].map{|m| Mail::AddressList.new((m.from || "").to_ascii).addresses}.flatten
    cc_addresses = params[:google_messages_to_look].map{|m| Mail::AddressList.new((m.cc || "").to_ascii).addresses}.flatten

    forbidden_emails = JulieAlias.all.map(&:email) + (params[:forbidden_emails] || [])

    (to_addresses + from_addresses + cc_addresses).select{ |contact|
      !forbidden_emails.map(&:downcase).include?(contact.address.try(:downcase))
    }.map{ |contact|
      {
          email: contact.address,
          name: contact.name
      }
    }.group_by{ |contact|
      contact[:email]
    }.map{ |email, contacts|
      contacts.max{|contact| "#{contact[:name]}".length}
    }
  end


  def computed_data
    message_classifications = messages.map{|m|
      m.message_classifications
    }.flatten.sort_by(&:updated_at).select(&:has_data?).compact
    last_message_classification = message_classifications.last

    appointment_nature = last_message_classification.try(:appointment_nature)
    {
        locale: last_message_classification.try(:locale) || self.account.try(:locale),
        timezone: last_message_classification.try(:timezone) || self.account.try(:default_timezone_id),
        appointment_nature: appointment_nature,
        summary: last_message_classification.try(:summary),
        duration: last_message_classification.try(:duration) || 60,
        location_nature: last_message_classification.try(:location_nature),
        location: last_message_classification.try(:location),
        attendees: JSON.parse(last_message_classification.try(:attendees) || "[]"),
        notes: last_message_classification.try(:notes),
        other_notes: last_message_classification.try(:other_notes),

        is_virtual_appointment: MessagesThread.virtual_appointment_natures.include?(appointment_nature),

        private: last_message_classification.try(:private),

        client_agreement: last_message_classification.try(:client_agreement),
        attendees_are_noticed: last_message_classification.try(:attendees_are_noticed),

        constraints: last_message_classification.try(:constraints),
        constraints_data: JSON.parse(last_message_classification.try(:constraints_data) || "[]"),

        number_to_call: last_message_classification.try(:number_to_call) || self.account.try(:number_to_call),

        date_times: message_classifications.map{|mc| JSON.parse(mc.date_times || "[]")}.flatten.sort_by{|dt|
          dt['date'] || "ZZZ"
        },
        last_message_sent_at: messages.select(&:from_me).sort_by(&:received_at).last.try(:received_at)
    }
  end

  def self.virtual_appointment_natures
    ["skype", "call", "webex"]
  end

  def self.items_to_classify_count
    MessagesThread.where(in_inbox: true).count
  end

  def self.several_accounts_detected google_thread
    contacts = self.contacts(google_messages_to_look: google_thread.messages)
    other_emails = contacts.map{|contact| contact[:email]}
    account_emails = (other_emails.map{|co| Account.find_account_email(co)}.uniq.compact.map(&:downcase) - JulieAlias.all.map(&:email))

    accounts = account_emails.map{|account_email|
      Account.create_from_email(account_email)
    }
    company_names = accounts.map{|account|
      account.company_hash.try(:[], 'name')
    }
    if company_names.select{ |company_name|
      company_name.nil?
    }.length > 0
      company_names.length > 1
    else
      company_names.uniq.length > 1
    end
  end

  def suggested_date_times
    messages.map{ |m|
      m.message_classifications.map(&:julie_action).compact.select{ |ja|
        ja.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES ||
            ja.action_nature == JulieAction::JD_ACTION_POSTPONE_EVENT ||
            ja.action_nature == JulieAction::JD_ACTION_CHECK_AVAILABILITIES
      }.map{ |ja|
        JSON.parse(ja.date_times || "[]")
      }
    }.flatten
  end

  def all_timezones
    (messages.map{ |m|
      m.message_classifications.map(&:julie_action).compact.select{ |ja|
        ja.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES
      }.map{ |ja|
        JSON.parse(ja.date_times).map{|dt| dt['timezone']}
      }
    }.flatten + messages.map{ |m|
      m.message_classifications.select{ |mc|
        mc.classification == MessageClassification::ASK_AVAILABILITIES
      }.map{ |mc|
        JSON.parse(mc.date_times).map{|dt| dt['timezone']}.select{|tz| tz.present?}
      }
    }.flatten).compact.uniq
  end

  def messages_to_classify
    messages.select{|m| m.message_classifications.empty?}
  end

  def received_at
    messages.map(&:received_at).max
  end

  def re_import
    existing_messages = []
    self.google_thread.messages.each do |google_message|
      google_message = Message.correct_google_message google_message
      message = self.messages.select{|m| m.google_message_id == google_message.id}.first
      unless message
        message = self.messages.create google_message_id: google_message.id,
                                       received_at: DateTime.parse(google_message.date),
                                       reply_all_recipients: Message.generate_reply_all_recipients(google_message).to_json,
                                       from_me: google_message.labelIds.include?("SENT")
      end
      message.google_message = google_message
      existing_messages << message
    end

    (self.messages - existing_messages).each do |message|
      message.clean_delete
    end

    self.messages = self.messages && existing_messages
  end

  def split message_ids
    google_message_ids = self.messages.select{|m| message_ids.include? m.id}.map(&:google_message_id)
    google_messages = self.google_thread.messages.select{|gm| google_message_ids.include? gm.id}
    updated_thread_id = nil

    messages_thread = nil

    google_messages.each do |google_message|
      google_message.threadId = updated_thread_id
      google_message.labelIds = google_message.labelIds.select{|label| label != "SENT"}
      updated_google_message = google_message.insert
      google_message.delete
      updated_thread_id = updated_google_message.thread_id

      # Create messages thread and messages in DB
      messages_thread ||= MessagesThread.create google_thread_id: updated_thread_id,
                                                in_inbox: true,
                                                account_email: self.account_email,
                                                account_name: self.account_name,
                                                subject: updated_google_message.subject,
                                                snippet: updated_google_message.snippet

      messages_thread.messages.create google_message_id: updated_google_message.id,
                                      received_at: DateTime.parse(updated_google_message.date),
                                      reply_all_recipients: Message.generate_reply_all_recipients(updated_google_message).to_json,
                                      from_me: updated_google_message.labelIds.include?("SENT")
    end






  end

  def sorted_message_classifications
    messages.map(&:message_classifications).flatten.sort_by(&:updated_at)
  end

  def scheduling_status
    sorted_mcs = sorted_message_classifications
    if sorted_mcs.select{|mc| mc.classification == MessageClassification::ASK_CREATE_EVENT && mc.julie_action.done}.length > 0
      EVENTS_CREATED
    elsif event_data[:event_id]
      EVENT_SCHEDULED
    elsif sorted_mcs.select{|mc| (mc.classification == MessageClassification::ASK_DATE_SUGGESTIONS || mc.classification == MessageClassification::ASK_AVAILABILITIES) && mc.julie_action.done}.length > 0
      SCHEDULING_EVENT
    else
      nil
    end
  end

  def possible_contacts_for_cache
    thread_contacts = []
    accounts = Account.accounts_cache
    contacts.each do |attendee|
      accounts.each do |email, account|
        all_emails = [account['email']] + account['email_aliases']

        if all_emails.include? attendee[:email]
          thread_contacts << {
              email: attendee[:email],
              name: account['full_name']
          }
        end
      end
    end

    (self.account.contacts_from_same_company + thread_contacts).uniq{|c| c[:email]}
  end

  def client_email
    if account
      contact_emails = contacts(with_client: true).map{|c| c[:email]}
      contact_emails.each do |email|
        if account.all_emails.map(&:downcase).include? "#{email}".downcase
          return email
        end
      end

      account_email
    else
      nil
    end
  end

  def self.find_account_email google_thread
    account_emails = self.find_account_emails(google_thread)
    if account_emails.length == 1
      account_emails[0]
    else
      nil
    end
  end

  def self.find_account_emails google_thread
    first_email = google_thread.messages.sort_by{|m| DateTime.parse(m.date)}.first
    email = ApplicationHelper.strip_email(first_email.from)
    account_emails = [Account.find_account_email(email)].compact

    # Account is not the sender
    if account_emails.empty?
      contacts = self.contacts(google_messages_to_look: [first_email])
      other_emails = contacts.map{|contact| contact[:email]}
      account_emails = (other_emails.map{|co| Account.find_account_email(co)}.uniq.compact.map(&:downcase) - JulieAlias.all.map(&:email))
    end

    account_emails
  end

  def event_data
    julie_actions = self.messages.map(&:message_classifications).flatten.map(&:julie_action).select(&:done).sort_by(&:updated_at)

    last_cancellation = julie_actions.select{|ja|
      ja.deleted_event
    }.last

    last_creation = julie_actions.select{|ja|
      ja.event_id
    }.last

    if last_creation && (last_cancellation.nil? || julie_actions.index(last_creation) > julie_actions.index(last_cancellation))
      {
          event_id: last_creation.event_id,
          event_url: last_creation.event_url,
          calendar_id: last_creation.calendar_id,
          appointment_nature: last_creation.message_classification.appointment_nature
      }
    else
      {
          event_id: nil,
          calendar_id: nil,
          appointment_nature: nil
      }
    end
  end

  def created_events_data
    julie_action = self.messages.map(&:message_classifications).flatten.map(&:julie_action).select{|ja|
      ja.done &&
          ja.action_nature == JulieAction::JD_ACTION_CREATE_EVENT
    }.sort_by(&:updated_at).last

    if julie_action
      JSON.parse(julie_action.events || "[]")
    else
      []
    end
  end

  def available_classifications
    if account_email
      s_status = scheduling_status
      if s_status == EVENTS_CREATED
        {
            manage_events: [
                MessageClassification::ASK_CREATE_EVENT
            ],
            other: [
                MessageClassification::GIVE_PREFERENCE,
                MessageClassification::UNKNOWN
            ]
        }
      elsif s_status == SCHEDULING_EVENT
        {
            event_scheduling: [
                MessageClassification::ASK_DATE_SUGGESTIONS,
                MessageClassification::ASK_AVAILABILITIES,
                MessageClassification::GIVE_INFO,
                MessageClassification::ASK_INFO,
            ],
            other: [
                MessageClassification::GIVE_PREFERENCE,
                MessageClassification::UNKNOWN
            ]
        }
      elsif s_status == EVENT_SCHEDULED
        {
            manage_scheduled_event: [
                MessageClassification::GIVE_INFO,
                MessageClassification::ASK_INFO,
                MessageClassification::ASK_CANCEL_APPOINTMENT
            ],
            event_rescheduling: [
                MessageClassification::ASK_DATE_SUGGESTIONS,
                MessageClassification::ASK_AVAILABILITIES
            ],
            other: [
                MessageClassification::GIVE_PREFERENCE,
                MessageClassification::UNKNOWN
            ]
        }
      elsif s_status == nil
        {
            event_scheduling: [
                MessageClassification::ASK_DATE_SUGGESTIONS,
                MessageClassification::ASK_AVAILABILITIES
            ],
            other: [
                MessageClassification::GIVE_PREFERENCE,
                MessageClassification::ASK_CREATE_EVENT,
                MessageClassification::ASK_CANCEL_EVENTS,
                MessageClassification::ASK_POSTPONE_EVENTS,
                MessageClassification::UNKNOWN
            ]
        }
      end
    else
      {
          other: [
              MessageClassification::UNKNOWN
          ]
      }
    end

  end

  def classification_category_for_classification classification
    available_classifications.select{|k, v|
      v.include? classification
    }.map{|k, v| k}.first.to_s
  end

  def locked_by_operator_name
    self.locked_by_operator.try(:name)
  end

  def self.get_locks_statuses_hash
    MessagesThread.where("locked_by_operator_id IS NOT NULL").map{|mt|
      {
        operator_name: mt.locked_by_operator_name,
        messages_thread_id: mt.id
      }
    }
  end


end