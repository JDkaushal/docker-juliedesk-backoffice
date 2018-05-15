module AutomaticProcessing
  module JulieActionsFlows

    class SendConfirmation < Base
      include CommonMethods

      def trigger
        event_details = get_event(@data_holder.get_thread_event_data[:event_id])

        @julie_action.text = "#{say_hi_text}#{get_send_confirmation_template({
                                                                                 locale: @data_holder.get_current_locale
                                                                             })}"

        booked_rooms_details = @data_holder.get_message_classification_booked_rooms_details

        update_event(
          {
            event_id: event_details.id,
            email: @data_holder.get_thread_owner_account.email,
            summary: @data_holder.get_message_classification_summary,
            description: @data_holder.get_message_classification_notes,
            attendees: @data_holder.get_present_attendees,
            location: @data_holder.get_message_classification_location,
            all_day: false,
            private: false,
            start: DateTime.parse(event_details.start['date']).in_time_zone(event_details.start['timezone']).to_s,
            end: DateTime.parse(event_details.end['date']).in_time_zone(event_details.end['timezone']).to_s,
            start_timezone: event_details.start['timezone'],
            end_timezone: event_details.end['timezone'],
            calendar_login_username: event_details.calendar_login_username, #Warning, here it could be different for clients with calendar rules
            meeting_room: booked_rooms_details.present? ? {used: true, booked_rooms: booked_rooms_details.values.flatten} : nil,
            create_skype_for_business_meeting: false # BNo support for sfb for now
          }
        )

      end
      
      private

      def get_event(event_id)
        if event_id.blank?
          raise AutomaticProcessing::Exceptions::EventFetchEventIdMissingError.new(@julie_action.id)
        end

        response = EventsManagement::BaseInterface.new.build_request(:fetch, {email: @data_holder.get_thread_owner_account_email, calendar_login_username: @data_holder.get_thread_owner_account_email, event_id: event_id})

        if response && response['status'] == 'success'
          OpenStruct.new(response['data'])
        else
          raise AutomaticProcessing::Exceptions::EventUpdateError.new(@julie_action.id)
        end
      end

      def update_event(params = {})
        response = EventsManagement::BaseInterface.new.build_request(:update, params)

        if response && response['status'] == 'success'
          # Don't do anything
        else
          raise AutomaticProcessing::Exceptions::EventUpdateError.new(@julie_action.id)
        end
      end

    end
  end
end