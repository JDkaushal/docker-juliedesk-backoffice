module EmailTemplates
  module Generation
    class Generator

      def initialize(template_type)
        @template_type = template_type
        @template_model = "EmailTemplates::Generation::Models::#{@template_type.to_s.camelize}".constantize
      end

      def generate(params, server_message = nil)
        @template_model.new(params.merge(server_message: server_message)).generate
      end

    end
  end
end