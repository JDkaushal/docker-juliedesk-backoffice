module AutomaticsEmails
  module Filters

    attr_reader :auto_email_type

    class Base

      def initialize(auto_email_type)
        @auto_email_type = auto_email_type
      end

      protected

      def filter(messages_thread)
        raise NotImplementedError.new("#{self.class.name} must implement the #filter method")
      end

    end
  end
end