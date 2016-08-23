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

        def get_validated_date
          Time.parse(@params['validate'])
        end

        def set_body
          add_to_output_array("#{I18n.translate('email_templates.date_confirmation.invitations_sent')} #{I18n.translate('email_templates.common.for')} #{I18n.translate("email_templates.appointment_types.#{get_appointment_type}")}")

          add_to_output_array(I18n.localize(get_validated_date, format: :date_confirmation).capitalize)

          add_to_output_array(I18n.translate('email_templates.location', location: get_location).capitalize)
        end

      end
    end
  end
end
