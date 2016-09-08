module EmailTemplates
  module Generation
    module Models

      class UnknownRequest < Base

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

        def set_body
          add_to_output_array(I18n.translate('email_templates.errors.unknown_request'))
        end

      end

    end
  end
end