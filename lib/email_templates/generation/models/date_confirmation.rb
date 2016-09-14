module EmailTemplates
  module Generation
    module Models
      class DateConfirmation < Base

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

        def get_timezone
          @params['timezone']
        end

        def get_validated_date
          Time.parse(@params['validate']).in_time_zone(get_timezone)
        end

        def set_body
          if @params['validate'].present?
            add_to_output_array("#{I18n.translate('email_templates.date_confirmation.invitations_sent')} #{I18n.translate('email_templates.common.for')} #{I18n.translate("email_templates.appointment_types.#{get_appointment_type}")}")

            add_to_output_array(I18n.localize(get_validated_date, format: :date_confirmation).capitalize)

            if get_location.present?
              add_to_output_array(I18n.translate('email_templates.location', location: get_location).capitalize)
            end

            phone_informations_question = check_ask_attendees_phone_numbers
            if phone_informations_question.present?
              add_to_output_array(phone_informations_question)
            end
          else
            if @params['suggested_dates'].present?
              add_to_output_array(I18n.translate('email_templates.date_confirmation.new_propositions', client_name: get_thread_owner['firstName'], appointment_type: I18n.translate("email_templates.appointment_types.#{get_appointment_type}"), location: get_location))
              get_suggested_dates.each do |date, times|
                add_to_output_array(EmailTemplates::Generation::Models::Utilities.format_date_proposition_output(date, times))
              end
              add_to_output_array(EmailTemplates::Generation::Models::Utilities.get_availability_question(get_suggested_dates_count))
            else
              add_to_output_array(I18n.translate('email_templates.errors.date_confirmation.no_fitting_date'))
            end
          end
        end

        def check_ask_attendees_phone_numbers
          attendees = get_non_client_attendees
          attendees_with_missing_infos = []

          if attendees
            attendees.each do |attendee|
              if attendee['mobile'].blank? && attendee['landline'].blank?
                attendees_with_missing_infos.push(attendee['firstName'])
              end
            end
          end

          if attendees_with_missing_infos.size > 0
            I18n.translate('email_templates.missing_informations.phone_number', attendees_names: attendees_with_missing_infos.join(', '))
          end
        end
      end
    end
  end
end
