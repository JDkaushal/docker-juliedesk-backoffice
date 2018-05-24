module AllowedAttendees

  class MessageManager
    attr_reader :message, :server_message, :julie_aliases_emails

    def initialize(message, server_message, julie_aliases_emails)
      @message = message
      @server_message = server_message
      @julie_aliases_emails = julie_aliases_emails
    end

    def extract_allowed_attendees
      Set.new(extract_from_aggregated_texts + extract_from_html + extract_from_recipients + extract_from_ics_if_any).to_a.compact.select{|attendee|
        attendee.length < 255 # Added by Nico on April 25 2018, Important to prevent activerecord errors when saving
      }
    end

    private

    def get_email_body_as_text
      @server_message['text']
    end

    def get_email_body_as_html
      @server_message['parsed_html']
    end

    def scan_emails(string)
      string
          .gsub(/à|â/, 'a')
          .gsub(/é|è|ê/, 'e')
          .gsub(/î/, 'i')
          .gsub(/ô/, 'o')
          .gsub(/û|ù/, 'u')
          .gsub(/ç/, 'c')
          .scan(AllowedAttendees::RegexpManager.email_regexp)
    end

    # We will run the Regexp only once on an aggregate of all the texts we need (email body, constraints ...)
    def aggregate_texts
      [get_email_body_as_text, get_constraints].join(' ')
    end

    def get_constraints
      message.message_classifications.map(&:constraints).join(' ')
    end

    def extract_from_aggregated_texts
      scan_emails(aggregate_texts)
    end

    def extract_from_html
      html = get_email_body_as_html
      return [] unless html.present?

      Nokogiri::HTML(html).search('//text()').map(&:text).map { |text| scan_emails(text) }.flatten
    end

    def extract_from_recipients
      recipients = Set.new

      message_recipients = Message.generate_reply_all_recipients(@server_message, @julie_aliases_emails)
      recipients.merge((message_recipients[:from] + message_recipients[:to] + message_recipients[:cc]).map{|recipient| recipient[:email]})

      recipients.to_a
    end

    def extract_from_ics_if_any
      @message.get_ics_attendees_if_any
    end
  end
end