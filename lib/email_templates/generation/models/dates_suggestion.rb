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

        def get_timezone
          @params['timezone']
        end

        def set_body
          if @params['suggested_dates'].present?
            add_to_output_array("#{get_thread_owner['firstName']} #{I18n.translate('email_templates.common.available', count: get_clients_count)} #{I18n.translate('email_templates.common.for')} #{I18n.translate("email_templates.appointment_types.#{get_appointment_type}")} #{get_location}")

            get_suggested_dates.each do |date, times|
              # current_date_string = "- #{I18n.localize(date, format: :date_suggestion).capitalize} #{I18n.translate('email_templates.common.at')} "
              # current_times_count = times.size
              # current_times_last_index = current_times_count - 1
              # current_times_before_last_index = current_times_count - 2
              #
              # times.each_with_index do |time, index|
              #   current_date_string += I18n.localize(time, format: :date_suggestion)
              #
              #   if current_times_count > 1 && index < current_times_last_index
              #     if index < current_times_before_last_index
              #       current_date_string += ', '
              #     else
              #       current_date_string += " #{I18n.translate('email_templates.common.or')} "
              #     end
              #   end
              # end

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