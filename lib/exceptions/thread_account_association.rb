module Exceptions
  module ThreadAccountAssociation

    class NoAccountsCacheProvidedError < StandardError
      def message
        "Please provide the accounts cache as a parameter"
      end

      def to_s
        "#{message} #{super}"
      end
    end

    class NoJulieAliasEmailsCacheProvidedError < StandardError
      def message
        "Please provide the julie alias emails cache as a parameter"
      end

      def to_s
        "#{message} #{super}"
      end
    end

    class NoJulieAliasesCacheProvidedError < StandardError
      def message
        "Please provide the julie alias cache as a parameter"
      end

      def to_s
        "#{message} #{super}"
      end
    end

    class MigratedMethodError < StandardError
      def message
        "The request method has been moved to ThreadAccountAssociation::Manager, please adapt logic accordingly"
      end

      def to_s
        "#{message} #{super}"
      end
    end
  end
end