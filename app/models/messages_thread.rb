class MessagesThread < ActiveRecord::Base

  has_many :messages

  def google_thread
    @google_thread ||= Gmail::Thread.get(self.google_thread_id)
  end

  def account
    @account ||= Account.create_from_email account_email
  end

  def contacts params = {}
    raw_contacts = google_thread.messages.map{|m| [m.to, m.from] + (m.cc.try(:split, ", ") || [])}.flatten

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

  def subject
    self.google_thread.messages.first.subject.gsub(/\ARe: /, "")
  end

  def computed_data
    message_classifications = messages.sort_by(&:received_at).map{|m|
      m.message_classifications.first
    }.compact

    {
        appointment_nature: message_classifications.map(&:appointment_nature).compact.last,
        appointment_nature_nature: (account.try(:default_appointments) || {})[message_classifications.map(&:appointment_nature).compact.last || "0"].try(:[], 'name'),
        summary: message_classifications.map(&:summary).compact.last,
        duration: message_classifications.map(&:duration).compact.last,
        location: message_classifications.map(&:location).compact.last,
        attendees: JSON.parse(message_classifications.map(&:attendees).compact.last || "[]"),
        notes: message_classifications.map(&:notes).compact.last,

        constraints: message_classifications.map(&:constraints).compact.last,

        date_times: message_classifications.map{|mc| JSON.parse(mc.date_times || "[]")}.flatten.uniq.sort,

        event_id: ""
    }
  end

  def self.items_to_classify_count
    result = 0
    MessagesThread.where(in_inbox: true).includes(:messages).each do |messages_thread|
      result += messages_thread.messages_to_classify.length
    end
    result
  end

  def suggested_date_times
    date_times_strings = messages.map{|m| m.julie_actions.select{|ja| ja.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES}.map{|ja| JSON.parse(ja.date_times || "[]")}}.flatten
    date_times_strings.map{|dts| DateTime.parse dts}
  end

  def messages_to_classify
    messages.select{|m| m.message_classifications.empty?}
  end
end