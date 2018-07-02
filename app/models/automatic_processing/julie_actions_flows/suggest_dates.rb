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
        
        generated_text = say_hi_text
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
             en: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'en'),
             fr: wordings['default_address'].try(:[], 'address_in_template').try(:[], 'fr')
          },
          missing_contact_info: missing_contact_info,
          date: date_slot,
          validate_suggestion_link:     validate_suggestion_link,
          show_other_suggestions_link:  show_other_suggestions_link
        })

        @julie_action.text = generated_text
      end

      def find_dates_to_suggest
        date_suggestions_response = AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, {
            account_email: @data_holder.get_thread_owner_account_email,
            thread_data: @data_holder.get_thread_computed_data,
            raw_constraints_data: JSON.parse(@data_holder.get_message_classification_raw_constraints),
            n_suggested_dates: 4,
            attendees: @data_holder.get_attendees,
            asap: @data_holder.get_message_classification_asap_constraint,
            message_id: nil # Keep this to nil, if set it is used to get previously suggested dates, if not set it causes errors
        })

        if !date_suggestions_response || date_suggestions_response[:error]
          raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionError.new(@julie_action.message_classification.message_id)
        end

        date_suggestions = date_suggestions_response['suggested_dates'] || []
        if date_suggestions.length < 2
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