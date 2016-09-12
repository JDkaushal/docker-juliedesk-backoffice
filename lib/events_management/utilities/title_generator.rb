module EventsManagement
  module Utilities
    class TitleGenerator < BaseGenerator

      attr_accessor :grouped_present_attendees
      attr_accessor :attendees_with_no_company_str, :attendees_with_company_str, :attendees_from_thread_owner_company_str, :appointment_type_str

      def initialize(params_handler)
        @params_handler = params_handler
        super(@params_handler.get_language)
      end

      def compute
        @grouped_present_attendees = @params_handler.get_attendees.group_by{|att| att['company']}

        compute_appointment_type_str

        companies = @grouped_present_attendees.keys
        if companies.length == 1
          only_one_company(companies[0])
        else
          multiple_company
        end

        result = I18n.translate("email_templates.events.title.appointment_type.#{@params_handler.get_appointment_type}")
        result += ' ' + [@attendees_with_no_company_str, @attendees_with_company_str, @attendees_from_thread_owner_company_str].reject{|str| str.blank?}.join(' | ')
      end

      private

      def compute_appointment_type_str
        @params_handler.get_appointment_type
      end

      def only_one_company(company)
        attendees = @grouped_present_attendees[company].reject{|att| att['is_assistant']}

        if company == ''
          @attendees_with_no_company_str = attendees.map do |attendee|
            EmailTemplates::Generation::Models::Utilities.normalize_attendee_name(attendee)
          end.join(' | ')
        else
          @attendees_with_company_str = company
          attendees_names = attendees.slice(0,5).map{|attendee| EmailTemplates::Generation::Models::Utilities.normalize_attendee_name(attendee)}
          @attendees_with_company_str += " [#{attendees_names.join(', ')}]"
        end
      end

      def multiple_company
        thread_owner_company = @params_handler.get_thread_owner['company']

        attendees_with_company_buffer = []

        @grouped_present_attendees.each do |company, attendees|
          if attendees.size > 0

            if company == ''
              @attendees_with_no_company_str = attendees.map do |attendee|
                EmailTemplates::Generation::Models::Utilities.normalize_attendee_name(attendee)
              end.join(' | ')
            elsif company == thread_owner_company
              @attendees_from_thread_owner_company_str = company
              @attendees_from_thread_owner_company_str += " [#{EmailTemplates::Generation::Models::Utilities.normalize_attendee_name(attendees[0])}]"
            else
              current_attendees_with_company_str = company
              if attendees.size == 1
                current_attendees_with_company_str += " [#{EmailTemplates::Generation::Models::Utilities.normalize_attendee_name(attendees[0])}]"
              end
              attendees_with_company_buffer.push(current_attendees_with_company_str)
            end
          end
        end

        @attendees_with_company_str = attendees_with_company_buffer.join(' | ')
      end

    end
  end

end