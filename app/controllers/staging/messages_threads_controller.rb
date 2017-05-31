if ENV['STAGING_APP']
  module Staging
    class MessagesThreadsController < StagingController
      def import_context_from_production
        uri = URI.parse(ENV['PRODUCTION_BASE_URL'] + "/api/v1/messages_thread_context?id=#{params[:server_thread_id]}")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        new_request = Net::HTTP::Get.new(uri, {'Content-Type' =>'application/json'})
        new_request.add_field('Authorization', 'EDx19D72bH7e5I64EXk1kwa4jXvynddS')

        response = http.request(new_request)

        context = JSON.parse(response.body)

        message_thread = MessagesThread.find_by_server_thread_id(params[:server_thread_id])

        message_thread.messages{|m| m.message_classifications.julie_action.destroy}
        message_thread.messages.each{|m| m.message_classifications.destroy_all}
        message_thread.messages.destroy_all

        last_julie_action = nil

        context['messages'].each do |message|
          #messages_classifications = context['messages_classifications'].first[message['id'].to_s]
          messages_classifications = context['messages_classifications']

          new_message = message_thread.messages.create(message.except("id", "messages_thread_id"))

          messages_classifications.present? && messages_classifications.each do |mcs_hash|
            mcs = messages_classifications.select{|hash| hash.keys.include?(message['id'].to_s)}

            if mcs.present?

              mcs = mcs.first[message['id'].to_s]

              mcs.each do |mc|
                new_mc = MessageClassification.new(mc.except("id", "message_id"))
                new_message.message_classifications << new_mc

                #julie_actions = context['julie_actions'].first[mc['id'].to_s]
                julie_action = context['julie_actions'].select{|hash| hash.keys.include?(mc['id'].to_s)}
                if julie_action.present?
                  julie_action = julie_action.first[mc['id'].to_s]
                  last_julie_action = new_mc.create_julie_action(julie_action.except("id", "message_classification_id", "event_id", "calendar_id"))
                end
              end
            end
          end
        end

        if context['current_event']['event_id'].present?
          clone_event_to_staging(context['current_event'].merge('email' => context['thread']['account_email'], 'last_julie_action' => last_julie_action))
        end

        redirect_to :back
      end


      private

      def clone_event_to_staging(event_params)
        event_data = retrieve_event_data(event_params)

        unless event_data['status'] == 'error'
          puts event_data['message']
          insert_event_in_staging_calendar(event_params['email'], event_params['last_julie_action'], event_data['data'])
        end
      end

      def retrieve_event_data(event_params)
        #client = HTTPClient.new(default_header: {
                                #     "Authorization" => ENV['JULIEDESK_APP_API_KEY']
                                # })
        client = HTTP.auth(ENV['JULIEDESK_APP_API_KEY'])
        response = client.get("#{ENV['JULIEDESK_APP_BASE_PATH']}/api/v1/calendar_proxy/event_get?email=#{event_params['email']}&calendar_login_username=#{event_params['calendar_login_username']}&event_id=#{Rack::Utils.escape(event_params['event_id'])}&event_url=#{event_params['event_url']}&calendar_id=#{Rack::Utils.escape(event_params['calendar_id'])}")

        #response = client.get("https://juliedesk-app.herokuapp.com/api/v1/calendar_proxy/event_get?email=#{event_params['email']}&calendar_login_username=#{event_params['calendar_login_username']}&event_id=#{Rack::Utils.escape(event_params['event_id'])}&event_url=#{event_params['event_url']}&calendar_id=#{Rack::Utils.escape(event_params['calendar_id'])}")

        response.parse
        #JSON.parse(response.body)
      end

      def insert_event_in_staging_calendar(account_email, last_julie_action, event_params)
        uri = URI.parse("#{ENV['STAGING_EVENT_API_ENDPOINT']}/api/v1/calendar_proxy/event_create")

        http = Net::HTTP.new(uri.host, uri.port)

        if !Rails.env.development?
          http.use_ssl = true
        end
        new_request = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
        new_request["Authorization"] = ENV['JULIEDESK_APP_API_KEY']

        real_attendees = event_params['attendees']

        event_params['attendees'] = []
        creation_params = event_params.select{|k, _| ['all_day', 'attendees', 'calendar_login_username', 'call_instructions', 'description', 'end', 'start', 'location', 'private', 'summary'].include?(k) }

        creation_params['end'] = creation_params['end']['dateTime']
        creation_params['start'] = creation_params['start']['dateTime']
        call_instructions = creation_params['call_instructions'].present? ? JSON.parse(creation_params['call_instructions']) : nil
        creation_params['call_instructions'] = call_instructions
        creation_params['calendar_login_username'] = ENV['STAGING_TARGET_EMAIL_ADDRESS']
        creation_params['email'] = ENV['STAGING_TARGET_EMAIL_ADDRESS']

        new_request.body = creation_params.to_json

        response = http.request(new_request)

        event_data = JSON.parse(response.body)

        event_id = event_data["data"]["event_id"]

        if last_julie_action.present?
          last_julie_action.update(event_id: event_id, calendar_login_username: ENV['STAGING_TARGET_EMAIL_ADDRESS'], calendar_id: event_data["data"]["calendar_id"])
        end

        save_real_attendees(event_id, real_attendees)
      end

      def save_real_attendees(event_id, attendees)
        StagingHelpers::MessagesThreadsHelper.save_attendees(event_id, attendees)

      end
    end
  end
end