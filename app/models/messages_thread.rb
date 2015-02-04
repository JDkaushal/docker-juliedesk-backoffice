class MessagesThread < ActiveRecord::Base

  has_many :messages

  def google_thread
    @google_thread ||= Gmail::Thread.get(self.google_thread_id)
  end

  def account
    @account ||= Account.create_from_email account_email
  end

  def contacts params = {}
    raw_contacts = google_thread.messages.map{|m| (m.to.try(:split, ",") || []) + [m.from] + (m.cc.try(:split, ", ") || [])}.flatten

    contact_emails = raw_contacts.map{|email| ApplicationHelper.strip_email email}.uniq - ["julie@juliedesk.com"]
    unless params[:with_client]
      contact_emails -= account.try(:all_emails) || []
    end

    contacts_email_and_names = raw_contacts.map{|email| [ApplicationHelper.strip_contact_name(email), ApplicationHelper.strip_email(email)]}

    result = []
    contact_emails.each do |email|
      name = contacts_email_and_names.select{|c| c[1] == email && c[0]}.first.try(:[], 0)
      result << {
          email: email,
          name: name
      }
    end

    result
  end

  def computed_data
    message_classifications = messages.sort_by(&:received_at).map{|m|
      m.message_classifications
    }.flatten.compact

    {
        locale: message_classifications.map(&:locale).compact.last || "fr",
        timezone: message_classifications.map(&:timezone).compact.last || "Europe/Paris",
        appointment_nature: message_classifications.map(&:appointment_nature).compact.last,
        appointment_nature_nature: (account.try(:default_appointments) || {})[message_classifications.map(&:appointment_nature).compact.last || "0"].try(:[], 'name'),
        summary: message_classifications.map(&:summary).compact.last,
        duration: message_classifications.map(&:duration).compact.last || 60,
        location: message_classifications.map(&:location).compact.last,
        attendees: JSON.parse(message_classifications.map(&:attendees).compact.last || "[]"),
        notes: message_classifications.map(&:notes).compact.last,

        constraints: message_classifications.map(&:constraints).compact.last,

        date_times: message_classifications.map{|mc| JSON.parse(mc.date_times || "[]")}.flatten.sort_by{|dt|
          dt['date'] || "ZZZ"
        },

        event_id: ""
    }
  end

  def self.items_to_classify_count
    #result = 0
    MessagesThread.where(in_inbox: true).count
    #.includes(:messages).each do |messages_thread|
    #  result += messages_thread.messages_to_classify.length
    #end
    #result
  end

  def suggested_date_times
    messages.map{ |m|
      m.message_classifications.map(&:julie_action).compact.select{ |ja|
        ja.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES
      }.map{ |ja|
        JSON.parse(ja.date_times)
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
    }.flatten).uniq
  end

  def messages_to_classify
    messages.select{|m| m.message_classifications.empty?}
  end

  def re_import
    existing_messages = []
    self.google_thread.messages.each do |google_message|
      message = self.messages.select{|m| m.google_message_id == google_message.id}.first
      unless message
        message = self.messages.create google_message_id: google_message.id, received_at: DateTime.parse(google_message.date), reply_all_recipients: Message.generate_reply_all_recipients(google_message).to_json
      end
      message.google_message = google_message
      message.correct_google_message
      existing_messages << message
    end

    (self.messages - existing_messages).each do |message|
      message.delete
    end

    self.messages = self.messages && existing_messages
  end

  def split message_ids
    google_message_ids = self.messages.select{|m| message_ids.include? m.id}.map(&:google_message_id)
    google_messages = self.google_thread.messages.select{|gm| google_message_ids.include? gm.id}
    updated_thread_id = nil
    google_messages.each do |google_message|
      google_message.threadId = updated_thread_id
      google_message.labelIds = ['INBOX']
      updated_google_message = google_message.insert
      google_message.delete
      updated_thread_id = updated_google_message.thread_id
    end
  end

  def self.find_account_email google_thread
    first_email = google_thread.messages.sort_by{|m| DateTime.parse(m.date)}.first
    email = ApplicationHelper.strip_email(first_email.from)
    account_email = Account.find_account_email email

    # Account is not the sender
    unless account_email
      other_emails = ((first_email.to.try(:split, ",") || []) + (first_email.cc.try(:split, ",") || [])).map{|email| ApplicationHelper.strip_email(email)}
      account_emails = other_emails.map{|co| Account.find_account_email(co)}.uniq - ["julie@juliedesk.com"]
      if account_emails.length == 1
        account_email = account_emails[0]
      end
    end

    account_email
  end
end