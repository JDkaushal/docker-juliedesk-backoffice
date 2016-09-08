module EmailTemplates
  module Generation
    class Generator

      def initialize(template_type)
        @template_type = template_type
        @template_model = "EmailTemplates::Generation::Models::#{@template_type.to_s.camelize}".constantize
      end

      def generate(params)
        @template_model.new(params).generate
      end

    end
  end
end