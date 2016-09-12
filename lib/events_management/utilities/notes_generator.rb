module EventsManagement
  module Utilities
    class NotesGenerator < BaseGenerator

      def initialize(params_handler)
        @params_handler = params_handler
        super(@params_handler.get_language)
        @output_array = []
      end

      def compute
        set_attendees_infos

        @output_array.join("\n\n")
      end
      
      private

      def set_attendees_infos
        @output_array.push(generate_thread_owner_notes)

        if @params_handler.get_attendees_without_thread_owner.size > 0
          @output_array.push(generate_attendees_notes)
        end
      end

      def generate_thread_owner_notes
        thread_owner = @params_handler.get_thread_owner
        output = I18n.translate('email_templates.events.notes.thread_owner_infos_boundary')
        output += "\n"
        output += EmailTemplates::Generation::Models::Utilities.compute_attendee_infos_in_notes(thread_owner)
        output += "\n----------------------------------------"
      end

      def generate_attendees_notes
        output = I18n.translate('email_templates.events.notes.attendees_infos_boundary')
        output += "\n"
        attendees_output = []

        @params_handler.get_attendees_without_thread_owner.each do |att|
          attendees_output.push(EmailTemplates::Generation::Models::Utilities.compute_attendee_infos_in_notes(att))
        end

        output += attendees_output.join("\n\n")
        output += "\n----------------------------------------"
      end

    end
  end
end
