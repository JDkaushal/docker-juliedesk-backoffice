class Message < ActiveRecord::Base

  belongs_to :messages_thread
  has_many :message_classifications

  attr_writer :google_message

  def validate_message_classifications
    JulieAction.create_from_message self
  end


  def google_message
    @google_message ||= Gmail::Message.get self.google_message_id
  end

  def from_me?
    google_message.from.include? "julie@juliedesk.com"
  end

  def self.import_emails
    google_threads = Gmail::Label.inbox.threads

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
            email = ApplicationHelper.strip_email google_thread.messages.sort_by(&:date).first.from
            account_email = Account.find_account_email email
            messages_thread.update_attribute :account_email, account_email
          end
        else
          email = ApplicationHelper.strip_email google_thread.messages.sort_by(&:date).first.from
          account_email = Account.find_account_email email

          messages_thread = MessagesThread.create google_thread_id: google_thread.id, in_inbox: true, account_email: account_email
        end

        sorted_messages = google_thread.messages.sort_by(&:date)

        snippet = sorted_messages.last.snippet
        messages_thread.update_attributes({subject: sorted_messages.first.subject, snippet: snippet})

        google_thread.messages.each do |google_message|
          message = Message.find_by_google_message_id google_message.id

          unless message
            messages_thread.messages.create google_message_id: google_message.id, received_at: DateTime.parse(google_message.date)
          end
        end
      end
    end

    nil
  end



end