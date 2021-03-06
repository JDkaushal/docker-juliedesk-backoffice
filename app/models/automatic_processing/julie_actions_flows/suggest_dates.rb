module AutomaticProcessing
  module JulieActionsFlows

    class SuggestDates < Base
      include CommonMethods

      def trigger(suggest_again = false)
        generate_template(suggest_again)
      end

      private

      def generate_template(suggest_again)
        @julie_action.date_times = find_dates_to_suggest.to_json

        wordings = @data_holder.get_appointment

        messages_thread         = @data_holder.get_messages_thread
        message_classification  = @data_holder.get_message_classification

        # Link Generation params
        date_slot                             = JSON.parse(@julie_action.date_times).map {|date_time| date_time['date'] }.first
        encrypted_thread_id                   = MessagesThread.encrypt_data(messages_thread.id)
        encrypted_validated_by                = MessagesThread.encrypt_data(message_classification.get_non_client_attendees.find(&:is_present).try(:email))


        # Generate links
        validate_suggestion_link    = TemplateService.new.generate_validate_time_slot_link(messages_thread.authentication_token, encrypted_thread_id, encrypted_validated_by, date_slot)
        show_other_suggestions_link = TemplateService.new.generate_show_time_slots_link(messages_thread.authentication_token, encrypted_thread_id, encrypted_validated_by)
        
        generated_text = say_hi_text.gsub(/\n/, '<br/>')
        generated_text += get_suggest_date_template({
          client_names: @data_holder.get_client_names,
          timezones: [@data_holder.get_thread_owner_default_timezone],
          default_timezone: @data_holder.get_thread_owner_default_timezone,
          duration: @data_holder.get_message_classification_duration,
          locale: @data_holder.get_current_locale,
          is_virtual: @data_holder.is_appointment_virtual?,
          appointment_in_email: {
             en: wordings['title_in_email']['en'],
             fr: wordings['title_in_email']['fr']
          },
          location_in_email: {
             #en: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'en'),
             #fr: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'fr')
          },
          missing_contact_info: missing_contact_info,
          date: date_slot,
          validate_suggestion_link:     validate_suggestion_link,
          show_other_suggestions_link:  show_other_suggestions_link
        })

        @julie_action.html = generated_text

        ClientSuccessTrackingHelpers.async_track('Slash - Suggestions Email Sent', messages_thread.account_email, {
            bo_thread_id: messages_thread.id,
            julie_aliases: messages_thread.julie_aliases_in_recipients,
            event_nature: @julie_action.message_classification.try(:appointment_nature),
            full_auto: true
        })
      end

      def find_dates_to_suggest
        date_suggestions_response = AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, {
            message_id: @data_holder.get_message_classification.message_id,
            julie_action_id: @julie_action.id,
            account_email: @data_holder.get_thread_owner_account_email,
            n_suggested_dates: 1,
            attendees: @data_holder.get_message_classification.get_present_attendees.map(&:to_h),
            thread_data: {
                appointment_nature: @data_holder.get_message_classification.try(:appointment_nature),
                location: @data_holder.get_message_classification_location,
                duration: @data_holder.get_message_classification_duration,
                timezone: @data_holder.get_message_classification_timezone
            },
            raw_constraints_data: JSON.parse(@data_holder.get_message_classification.constraints_data || '[]')
        })

        if !date_suggestions_response || date_suggestions_response[:error]
          raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionError.new(@julie_action.message_classification.message_id)
        end

        date_suggestions = date_suggestions_response['suggested_dates'] || []
        if date_suggestions.length < 1
          raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionNotEnoughSuggestionsError.new(@julie_action.message_classification.message_id)
        end

        date_suggestions.map{|date_suggestion|
          {
              timezone: date_suggestions_response['timezone'],
              date: date_suggestion
          }
        }
      end
    end
  end
end