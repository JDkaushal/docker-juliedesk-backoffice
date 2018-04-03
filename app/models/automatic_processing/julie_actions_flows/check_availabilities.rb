module AutomaticProcessing
  module JulieActionsFlows
    
    class CheckAvailabilities < Base
      include CommonMethods

      def trigger
        ai_verify_dates_data = ask_ai_verify_dates
        # Store in DB on message classification 'verified_dates_by_ai'
        chosen_date_for_check_availabilities = ai_verify_dates_data[:date_to_book]
        timezone_returned_by_ai = ai_verify_dates_data[:timezone]
        meeting_rooms_for_check_availabilities = ai_verify_dates_data[:meeting_rooms_to_book]

        wordings = @data_holder.get_appointment

        update_message_classification({
          chosen_date_for_check_availabilities: chosen_date_for_check_availabilities,
          meeting_rooms_for_check_availabilities: meeting_rooms_for_check_availabilities,
          timezone_returned_by_ai: timezone_returned_by_ai
        })

        @julie_action.text = "#{say_hi_text}#{get_invitations_sent_template({
                                                                       client_names: @data_holder.get_client_names,
                                                                       timezones: [timezone_returned_by_ai],
                                                                       locale: @data_holder.get_current_locale,
                                                                       is_virtual: false,
                                                                       attendees: @data_holder.get_present_attendees,
                                                                       appointment_in_email: {
                                                                           en: wordings['title_in_email']['en'],
                                                                           fr: wordings['title_in_email']['fr']
                                                                       },
                                                                       location_in_email: {
                                                                           en: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'en'),
                                                                           fr: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'fr')
                                                                       },
                                                                       should_ask_location: self.should_ask_location?,
                                                                       missing_contact_info: missing_contact_info,
                                                                       date: chosen_date_for_check_availabilities.to_s
                                                                   })}"

        create_event(
            {
                email: @data_holder.get_thread_owner_account.email,
                summary: @data_holder.get_message_classification_summary,
                description: @data_holder.get_message_classification_notes,
                attendees: @data_holder.get_present_attendees,
                location: @data_holder.get_message_classification_location,
                all_day: false,
                private: false,
                start: chosen_date_for_check_availabilities.to_s,
                end: "#{chosen_date_for_check_availabilities + @data_holder.get_message_classification_duration.minutes}",
                start_timezone: timezone_returned_by_ai,
                end_timezone: timezone_returned_by_ai,
                calendar_login_username: @data_holder.get_thread_owner_account_email, #Warning, here it could be different for clients with calendar rules
                meeting_room: meeting_rooms_for_check_availabilities.present? ? {used: true, booked_rooms: meeting_rooms_for_check_availabilities} : nil,
                create_skype_for_business_meeting: false # BNo support for sfb for now
            }
        )
      end

      private

      def update_message_classification(params)
        message_classification_params = {verify_dates_by_ai: {verified_dates: [params[:chosen_date_for_check_availabilities]], meeting_rooms_to_book: {params[:chosen_date_for_check_availabilities] => params[:meeting_rooms_for_check_availabilities] }, timezone: params[:timezone_returned_by_ai]}}

        if meeting_rooms_for_check_availabilities.present?
          rooms_details = meeting_rooms_for_check_availabilities.map{|room_email| @data_holder.get_meeting_room_details(room_email)}

          booked_rooms_details = rooms_details.each_with_index.inject({}) do |h, room_detail_with_index|
            room_detail, index = room_detail_with_index

            h[index] = {summary: room_detail['summary'], id: room_detail['id'], location: room_detail['location']}
          end
          message_classification_params[:booked_rooms_details] = booked_rooms_details
        end

        @data_holder.get_message_classification.update(message_classification_params)
      end

      def create_event(params = {})
        response = EventsManagement::BaseInterface.new.build_request(:create, params)

        if response && response['status'] == 'success'
          @julie_action.update({
                          calendar_id: response['data']['calendar_id'],
                          calendar_login_username: account.email,
                          event_id: response['data']['id']
                      })
        else
          raise AutomaticProcessing::Exceptions::EventCreationError.new(@julie_action.id)
        end
      end

      def ask_ai_verify_dates
        verify_dates_by_ai
      end

      def verify_dates_by_ai
        string_date_times = get_dates_to_verify
        message_main_interpretation = @data_holder.get_message_classification_main_interpretation

        if string_date_times.length == 0
          raise AutomaticProcessing::Exceptions::ConscienceNoDatesToValidateError.new(@julie_action.message_classification.id)
        else
          params = {
              account_email: @data_holder.get_thread_owner_main_email,
              thread_data: @data_holder.get_thread_computed_data,
              dates_to_check: string_date_times,
              server_message_id: @data_holder.get_message_server_id,
              today_date: DateTime.now.strftime("%Y-%m-%dT%H:%M:%S"),
              attendees: @data_holder.get_attendees,
              check_differences: true,
              message_id: @data_holder.get_message_id,
              message_classification_identifier: @data_holder.get_message_classification_identifier,
              client_on_trip: message_main_interpretation['client_on_trip'].try(:[], 'label'),
              raw_constraints_data: @data_holder.get_message_classification_raw_constraints,
              all_conditions_satisfied: false
          }.merge(
              AutomaticProcessing::MeetingRoomsManager.new(@data_holder).get_meeting_rooms_params
          )

          handle_verify_dates_response(AI_PROXY_INTERFACE.build_request(:verify_dates_v11, params))
        end
      end

      def handle_verify_dates_response(resp)
        if resp['error'].blank? && resp['status'] != 'fail'
          result = {}
          validated_date = resp['date_validates'].first


          result[:date_to_book] = DateTime.parse(validated_date['date'])
          result[:timezone] = resp['timezone']
          result[:meeting_rooms_to_book] = validated_date['meeting_rooms_to_book'].values.flatten

          result
        else
          raise AiVerifyDatesFailureError.new(@data_holder.get_message_classification)
        end
      end

      def get_dates_to_verify
        dates = @data_holder.get_message_classification_date_times

        dates.map do |data|
          DateTime.parse(data['date']).in_time_zone(data['timezone']).strftime("%Y-%m-%dT%H:%M:%S")
        end
      end
      
    end
  end
end