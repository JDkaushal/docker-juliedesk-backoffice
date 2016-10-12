module EmailTemplates
  module Generation
    module Models
      class DatesSuggestion < Base

        REQUIRED_PARAMS = []

        def initialize(params)
          super(params)
        end

        def get_required_params
          REQUIRED_PARAMS
        end

        def generate
          super
        end

        private

        # Override of /lib/email_templates/generation/models/base.rb
        def set_greetings_sentence
          if get_attendees_without_thread_owner_count > 1
            add_to_output_array(I18n.translate("email_templates.common.hello_only", count: get_attendees_without_thread_owner_count))
          else
            add_to_output_array(I18n.translate("email_templates.greetings.unformal", client_name: get_attendees_without_thread_owner[0]['firstName']))
          end
        end

        def get_timezone
          @params['timezone']
        end

        def first_time_suggesting?
          @params['first_suggestion']
        end

        def set_body
          if @params['suggested_dates'].present?
            if first_time_suggesting?
              add_to_output_array("#{get_thread_owner['firstName']} #{I18n.translate('email_templates.common.available', count: get_clients_count)} #{I18n.translate('email_templates.common.for')} #{I18n.translate("email_templates.appointment_types.#{get_appointment_type}")} #{get_location}")
            else
              add_to_output_array(I18n.translate('email_templates.date_confirmation.new_propositions', client_name: get_thread_owner['firstName'], appointment_type: I18n.translate("email_templates.appointment_types.#{get_appointment_type}"), location: get_location))
            end

            get_suggested_dates.each do |date, times|
              add_to_output_array(EmailTemplates::Generation::Models::Utilities.format_date_proposition_output(date, times))
            end

            add_to_output_array(EmailTemplates::Generation::Models::Utilities.get_availability_question(get_suggested_dates_count))
          else
            add_to_output_array(I18n.translate('email_templates.errors.dates_suggestion.no_suggestions'))
          end
        end

      end
    end

  end
end