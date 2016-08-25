module Ai
  module EmailProcessing
    class Processor
      include ActionView::Helpers::TextHelper
      include ERB::Util

      def initialize(message_id, julie_aliases_cache)
        @message = Message.find(message_id)
        @message = @message.messages_thread.re_import.find{|m| m.id == @message.id}
        @server_message = @message.server_message
        @server_message_id = @server_message['id']
        @julie_aliases_cache = julie_aliases_cache || JulieAlias.all
      end

      def self.perform_later(message_id)
        self.new(message_id, nil).process
      end

      def process
        begin
          julia_response = AiProxy.new.build_request(:ask_julia, {id: @server_message_id})
          @message.message_interpretations.create(question: :full_ai, raw_response: julia_response.to_json)

          julie_aliases = Message.julie_aliases_from_server_message(@server_message, {julie_aliases: @julie_aliases_cache})

          julia_response['julie_alias'] = julie_aliases.first

          email_text = dispatch_request_type(julia_response)

          send_response_email(email_text, julia_response['julie_alias'])
        rescue => e
          if Rails.env.production?
            send_response_email(error_response_template, JulieAlias.first)
          else
            raise e
          end
        end
      end
      
      private

      def dispatch_request_type(julia_response)

        current_appointment_type = case julia_response['request'].to_sym
                                     when :ask_date_suggestions
                                       :dates_suggestion
                                     when :ask_availabilities
                                       create_event(julia_response)
                                       :date_confirmation
                                   end

        EmailTemplates::Generation::Generator.new(current_appointment_type).generate(julia_response)
      end

      def create_event(julia_response)
        start_date = Time.parse(julia_response['validate'])
        end_date = start_date + julia_response['duration'].minutes

        create_params = {
            email:"stagingjuliedesk@gmail.com",
            calendar_login_username:"stagingjuliedesk@gmail.com",
            all_day:false,
            attendees:julia_response['participants'].map{|att| {email: att['email']}},
            call_instructions:{},
            description:"Event created By JuliA",
            end:end_date,
            end_timezone:"Europe/Berlin",
            location:julia_response['location'],
            meeting_room:{used: false},
            private:false,
            start:start_date,
            start_timezone:"Europe/Berlin",
            summary:"JuliA Event"
        }

        response = EventsManagement::Crud::Creator.new().process(create_params)['data']

        unless response['success']
          raise("Error while creating event from server_message_id: #{@message.server_message_id}")
        end

        response
      end

      def send_response_email(email_text, julie_alias)
        initial_recipients = @message.initial_recipients

        email_params = {
            subject: @server_message['subject'],
            from: julie_alias.generate_from,
            to: initial_recipients[:to].join(", "),
            cc: initial_recipients[:cc].join(", "),
            text: "#{email_text}",
            html: "#{text_to_html(email_text)}",
            quote_replied_message: true,
            quote_forward_message: false,
            reply_to_message_id:  @message.server_message_id
        }

        EmailServer.deliver_message(email_params)
      end

      def text_to_html text
        text.split("\n").map{|line| "<div>#{(line.present?)?h(line):"<br>"}</div>"}.join("\n").html_safe
      end

      def error_response_template
        'Sorry, I could not find an appropriate response to your request'
      end

    end
  end
  
end