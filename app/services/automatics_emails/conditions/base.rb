module AutomaticsEmails
  module Conditions
    class Base

      attr_reader :filtered_data
      def initialize(filtered_data)
        @filtered_data = filtered_data

      end

      protected

      def process(data)
        raise NotImplementedError.new("#{self.class.name} must implement the #process method, that will apply the condition to the base and returns true or false")
      end


    end
  end
end