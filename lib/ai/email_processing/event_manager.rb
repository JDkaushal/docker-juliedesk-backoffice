module Ai
  module EmailProcessing
    class EventManager

      attr_accessor :calendar_login

      def initialize(calendar_login)
        @calendar_login = calendar_login
      end

      def create(params, julia_response)
        confirmed_date = julia_response['validate']

        if confirmed_date.present?
          start_date = Time.parse(confirmed_date)
          end_date = start_date + julia_response['duration'].minutes

          create_params = {
              email:params[:thread_owner_account_email],
              calendar_login_username: @calendar_login['username'],
              all_day:false,
              attendees:julia_response['participants'].map{|att| {email: att['email']}},
              call_instructions:{},
              end:end_date,
              end_timezone:julia_response['timezone'],
              location:julia_response['location'],
              meeting_room:{used: false},
              private:false,
              start:start_date,
              start_timezone:julia_response['timezone']
          }

          params_handler = EmailTemplates::DataHandlers::ParametersHandler.new(julia_response)
          create_params[:summary] = EventsManagement::Utilities::TitleGenerator.new(params_handler).compute
          create_params[:description] = EventsManagement::Utilities::NotesGenerator.new(params_handler).compute

          response = EventsManagement::Crud::Creator.new.process(create_params)['data']

          unless response['success']
            raise("Error while creating event from server_message_id: #{params[:server_message_id]}")
          end

          response
        end
      end

      def update(params, julia_response)
        event_data = self.fetch(params[:messages_thread_event_data].merge(email: params[:thread_owner_account_email]))['data']

        event_data['email'] = params[:thread_owner_account_email]
        event_data['attendees'] = julia_response['participants'].map{|att| {email: att['email']}}
        event_data['location'] = julia_response['location']

        current_start_date = event_data['start']['datetime'] || event_data['start']['date']
        event_data['end'] = Time.parse(current_start_date) + julia_response['duration'].minutes

        params_handler = EmailTemplates::DataHandlers::ParametersHandler.new(julia_response)
        event_data[:summary] = EventsManagement::Utilities::TitleGenerator.new(params_handler).compute
        event_data[:description] = EventsManagement::Utilities::NotesGenerator.new(params_handler).compute

        response = EventsManagement::Crud::Updator.new.process(event_data)['data']

        unless response['success']
          raise("Error while updating event from server_message_id: #{params[:server_message_id]}")
        end

        response
      end

      def fetch(params)
        EventsManagement::Crud::Fetchor.new.process(params)['data']
      end

    end
  end
end
