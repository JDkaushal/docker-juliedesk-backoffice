module AutomaticProcessing
  module JulieActionsFlows

    class SuggestDates < Base
      include CommonMethods

      def trigger
        @julie_action.date_times = find_dates_to_suggest.to_json
        wordings = @data_holder.get_appointment

        @julie_action.text = "#{say_hi_text}#{get_suggest_dates_template({
                                                                    client_names: @data_holder.get_client_names,
                                                                    timezones: [@data_holder.get_thread_owner_default_timezone],
                                                                    default_timezone: @data_holder.get_thread_owner_default_timezone,
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
                                                                    dates: JSON.parse(@julie_action.date_times).map{|date_time| date_time['date']}
                                                                })}"
      end

      private

      def find_dates_to_suggest
        date_suggestions_response = AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, {
            account_email: @data_holder.get_thread_owner_account_email,
            thread_data: @data_holder.get_thread_computed_data,
            raw_constraints_data: @data_holder.get_message_classification_raw_constraints,
            n_suggested_dates: 4,
            attendees: @data_holder.get_attendees,
            asap: @data_holder.get_message_classification_asap_constraint,
            message_id: nil # Keep this to nil, if set it is used to get previously suggested dates, if not set it causes errors
        })

        if !date_suggestions_response || date_suggestions_response[:error]
          raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionError.new(self.message_classification.message.id)
        end

        date_suggestions = date_suggestions_response['suggested_dates'] || []
        if date_suggestions.length < 2
          raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionNotEnoughSuggestionsError.new(self.message_classification.message.id)
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