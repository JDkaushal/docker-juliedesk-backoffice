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
        @message_thread = @message.messages_thread
        @thread_owner_account = @message_thread.account
      end

      def self.perform_later(message_id)
        self.new(message_id, nil).process
      end

      def process
        begin
          julia_response = AiProxy.new.build_request(:ask_julia, {id: @server_message_id})
          @message.message_interpretations.create(question: :full_ai, raw_response: julia_response.to_json)

          # this is used by JuliA later on to process the ask_availabilities request
          new_classif = @message.message_classifications.create({
                                                                  operator: 'julie_full_ai',
                                                                  classification: julia_response['request'],
                                                                  appointment_nature: julia_response['appointment'],
                                                                  locale: julia_response['language'],
                                                                  attendees: (julia_response['participants'] || []).to_json,
                                                                  location: julia_response['location'],
                                                                  date_times: '[]',
                                                                  duration: julia_response['duration'],
                                                                  timezone: julia_response['timezone']
                                                                })

          new_julie_action = new_classif.append_julie_action
          new_julie_action.update({
                                      done: true,
                                      server_message_id: @server_message_id,
                                      date_times: (julia_response['suggested_dates'] || []).map{|date| {date: Time.parse(date).strftime('%Y-%m-%dT%H:%M:%S+00:00'), timezone: julia_response['timezone']}}.to_json
                                  })

          julie_aliases = Message.julie_aliases_from_server_message(@server_message, {julie_aliases: @julie_aliases_cache})

          julia_response['julie_alias'] = julie_aliases.first

          email_text = dispatch_request_type(julia_response)

          send_response_email(email_text, julia_response['julie_alias'])
        rescue => e
          if Rails.env.production?
            send_response_email(error_response_template, JulieAlias.find_by(email: 'jul.ia@juliedesk.com'))
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
                                       create_event(julia_response)[:template]
                                   end

        EmailTemplates::Generation::Generator.new(current_appointment_type).generate(julia_response)
      end

      def create_event(julia_response)
        confirmed_date = julia_response['validate']

        if confirmed_date.present?
          calendar_login = @message_thread.calendar_login

          start_date = Time.parse(confirmed_date)
          end_date = start_date + julia_response['duration'].minutes

          create_params = {
              email:@thread_owner_account.email,
              calendar_login_username: calendar_login['username'],
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

          response = EventsManagement::Crud::Creator.new.process(create_params)['data']

          unless response['success']
            raise("Error while creating event from server_message_id: #{@message.server_message_id}")
          end

          {template: :date_confirmation}
        else
          {template: :not_available}
        end
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