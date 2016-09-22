module EmailTemplates
  module Generation
    module Models

      class WaitingForContact < Base

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

        def get_waiting_for
          @params['waiting_for']
        end

        def get_waiting_for_attendees
          waiting_for = get_waiting_for

          result = []
          if waiting_for
            result = get_attendees_without_thread_owner.select{ |att| waiting_for.include?(att['email']) }.map{|att| att['firstName']}
          end

          result
        end

        def set_body
          add_to_output_array(I18n.translate('email_templates.waiting_for_contact', attendees_names: get_waiting_for_attendees.join(', ')))
        end

      end

    end
  end
end
