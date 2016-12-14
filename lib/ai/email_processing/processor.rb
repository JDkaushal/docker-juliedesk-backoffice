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

          if julia_response[:error]
            # Raise error so we go execute the catch code
            raise RuntimeError.new("AI returned error with response => #{julia_response}")
          end

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
                                                                  timezone: julia_response['timezone'],
                                                                  constraints_data: (julia_response['constraints_data'] || []).to_json
                                                                })

          # Manage the ClientContacts database entries
          #Ai::DataHandlers::AttendeesHandler.new(@thread_owner_account, (julia_response['participants'] || [])).handle

          new_julie_action = new_classif.append_julie_action
          new_julie_action.update({
                                      done: true,
                                      server_message_id: @server_message_id,
                                      date_times: (julia_response['suggested_dates'] || []).map{|date| {date: Time.parse(date).strftime('%Y-%m-%dT%H:%M:%S+00:00'), timezone: julia_response['timezone']}}.to_json
                                  })

          julie_aliases = Message.julie_aliases_from_server_message(@server_message, {julie_aliases: @julie_aliases_cache})

          julia_response['julie_alias'] = julie_aliases.first
          julia_response['message_id'] = @message.id

          email_text = dispatch_request_type(julia_response, new_julie_action)

          # After the event creation, we update the statuses
          new_classif.update(thread_status: new_classif.computed_thread_status)
          @message_thread.update(status: @message_thread.reload.suggested_current_status)

          EmailServer.archive_thread(messages_thread_id: @message_thread.server_thread_id)

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

      def dispatch_request_type(julia_response, new_julie_action)

        current_request = julia_response['request'].to_sym
        current_appointment_type = case current_request
                                     when :ask_date_suggestions
                                       :dates_suggestion
                                     when :ask_availabilities
                                       :date_confirmation
                                     when :give_info
                                       :event_updated
                                     when :wait_for_contact
                                       :waiting_for_contact
                                     else
                                       :unknown_request
                                   end

        text = EmailTemplates::Generation::Generator.new(current_appointment_type).generate(julia_response, @server_message)

        # After email generation actions
        case current_request
          when :ask_availabilities
            created_event_details = Ai::EmailProcessing::EventManager.new(@message_thread.calendar_login).create({
                                                        thread_owner_account_email:@thread_owner_account.email,
                                                        server_message_id:@message.server_message_id
                                                     },julia_response)

            new_julie_action.update(event_id: created_event_details['event_id'], calendar_id: created_event_details['calendar_id'], calendar_login_username: @message_thread.calendar_login['username'])
          when :give_info
            Ai::EmailProcessing::EventManager.new(@message_thread.calendar_login).update({
                             messages_thread_event_data: @message_thread.event_data,
                             thread_owner_account_email:@thread_owner_account.email,
                             server_message_id:@message.server_message_id
                         },julia_response)

        end

        text
      end

      # def create_event(julia_response)
      #   confirmed_date = julia_response['validate']
      #
      #   if confirmed_date.present?
      #     calendar_login = @message_thread.calendar_login
      #
      #     start_date = Time.parse(confirmed_date)
      #     end_date = start_date + julia_response['duration'].minutes
      #
      #     create_params = {
      #         email:@thread_owner_account.email,
      #         calendar_login_username: calendar_login['username'],
      #         all_day:false,
      #         attendees:julia_response['participants'].map{|att| {email: att['email']}},
      #         call_instructions:{},
      #         description:"Event created By JuliA",
      #         end:end_date,
      #         end_timezone:julia_response['timezone'],
      #         location:julia_response['location'],
      #         meeting_room:{used: false},
      #         private:false,
      #         start:start_date,
      #         start_timezone:julia_response['timezone']
      #     }
      #
      #     create_params[:summary] = EventsManagement::Utilities::TitleGenerator.new(EmailTemplates::DataHandlers::ParametersHandler.new(julia_response)).compute
      #     create_params[:description] = EventsManagement::Utilities::NotesGenerator.new(EmailTemplates::DataHandlers::ParametersHandler.new(julia_response)).compute
      #
      #     response = EventsManagement::Crud::Creator.new.process(create_params)['data']
      #
      #     unless response['success']
      #       raise("Error while creating event from server_message_id: #{@message.server_message_id}")
      #     end
      #   end
      # end

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
        text.split("\n").map{|line| "<div>#{(line.present?)?line:"<br>"}</div>"}.join("\n")
      end

      def error_response_template
        I18n.translate('email_templates.errors.common', locale: @thread_owner_account.locale)
      end

    end
  end
end