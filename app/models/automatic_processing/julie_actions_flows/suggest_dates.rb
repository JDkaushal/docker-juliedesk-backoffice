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

        preambule = if suggest_again
                      "#{say_hi_text}#{get_client_unvailable_template({client_names: @data_holder.get_client_names})}"
                    else
                      say_hi_text
                    end

        @julie_action.text = "#{preambule}#{get_suggest_dates_template({
                                                                           client_names: @data_holder.get_client_names,
                                                                           timezones: [@data_holder.get_thread_owner_default_timezone],
                                                                           default_timezone: @data_holder.get_thread_owner_default_timezone,
                                                                           locale: @data_holder.get_current_locale,
                                                                           is_virtual: @data_holder.is_appointment_virtual?,
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