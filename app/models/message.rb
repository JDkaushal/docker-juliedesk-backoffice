class Message < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include ERB::Util

  belongs_to :messages_thread
  has_many :message_classifications

  attr_writer :google_message

  def validate_message_classifications
    JulieAction.create_from_message self
  end

  def correct_google_message
    @google_message.text ||= @google_message.body
    @google_message.html ||= h(simple_format(@google_message.text))
    @google_message.body = nil
  end

  def google_message
    unless @google_message
      @google_message = Gmail::Message.get self.google_message_id

      correct_google_message
    end

    @google_message
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
    gm = google_message.reply_all_with(Gmail::Message.new(text: ""))
    email_regexp = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
    {
        to: (gm.to || "").split(",").select{|dest| email_regexp.match(dest)}.map{|dest|
          {
              email: email_regexp.match(dest)[0],
              name: dest.gsub(email_regexp, "").gsub("<>", "").gsub(/\A\s+/, "").gsub(/\s+\z/, "")
          }
        },
        cc: (gm.cc || "").split(",").select{|dest| email_regexp.match(dest)}.map{|dest|
          {
              email: email_regexp.match(dest)[0],
              name: dest.gsub(email_regexp, "").gsub("<>", "").gsub(/\A\s+/, "").gsub(/\s+\z/, "")
          }
        }
    }
  end




end