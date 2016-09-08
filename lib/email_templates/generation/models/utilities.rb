module EmailTemplates
  module Generation
    module Models

      class Utilities

        def self.format_date_proposition_output(date, times)

            current_date_string = "- #{I18n.localize(date, format: :date_suggestion).capitalize} #{I18n.translate('email_templates.common.at')} "
            current_times_count = times.size
            current_times_last_index = current_times_count - 1
            current_times_before_last_index = current_times_count - 2

            times.each_with_index do |time, index|
              current_date_string += I18n.localize(time, format: :date_suggestion)

              if current_times_count > 1 && index < current_times_last_index
                if index < current_times_before_last_index
                  current_date_string += ', '
                else
                  current_date_string += " #{I18n.translate('email_templates.common.or')} "
                end
              end
            end

          current_date_string
        end

        def self.get_availability_question(date_count)
          I18n.translate('email_templates.dates.availability_question', count: date_count)
        end
          
      end
    end
  end
end

