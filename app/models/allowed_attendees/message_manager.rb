module AllowedAttendees

  class MessageManager
    attr_reader :message, :server_message, :julie_aliases_emails

    def initialize(message, server_message, julie_aliases_emails)
      @message = message
      @server_message = server_message
      @julie_aliases_emails = julie_aliases_emails
    end

    def extract_allowed_attendees
      Set.new(extract_from_aggregated_texts + extract_from_recipients + extract_from_ics_if_any).to_a
    end

    private

    def get_email_body_as_text
      @server_message['text']
    end

    def emails_regexp
      @emails_regex ||= AllowedAttendees::RegexpManager.email_regexp
    end

    # We will run the Regexp only once on an aggregate of all the texts we need (email body, constraints ...)
    def aggregate_texts
      [get_email_body_as_text, get_constraints].join(' ')
    end

    def get_constraints
      message.message_classifications.map(&:constraints).join(' ')
    end

    def extract_from_aggregated_texts
      aggregate_texts.scan(emails_regexp)
    end

    def extract_from_recipients
      recipients = Set.new

      message_recipients = Message.generate_reply_all_recipients(@server_message, @julie_aliases_emails)
      recipients.merge((message_recipients[:from] + message_recipients[:to] + message_recipients[:cc]).map{|recipient| recipient[:email]})

      recipients.to_a
    end

    def extract_from_ics_if_any
      attendees_emails = []

      if @server_message['attachments_data'].present?

        ics_data = fetch_ics

        if ics_data.present?
          parsed_ics_data = Icalendar::Calendar.parse(ics_data)
          if parsed_ics_data.present?
            attendees_emails = parsed_ics_data.first.events.first.attendee.map(&:to)
          end
        end
      end

      attendees_emails
    end

    def fetch_ics
      # ics_data = nil
      #
      # http = HTTP.auth(ENV['EMAIL_SERVER_API_KEY'])
      # ssl_context = OpenSSL::SSL::SSLContext.new
      #
      # request = http.get("#{EmailServer::SERVER_PATH}/messages/#{@server_message['id']}/get_attachment?attachment_id=#{@server_message['attachments_data'][0]['attachment_id']}", ssl_context: ssl_context)
      #
      # if request.code == 200
      #   ics_data = request.readpartial
      # end

      #ics_data
      EmailServerInterface.new.build_request(:fetch_ics, {message_id: @server_message['id'], attachment_id: @server_message['attachments_data'][0]['attachment_id']})['data']
    end
  end
end