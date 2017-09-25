module AutomaticsEmails
  module Conditions
    class CountLimit < Base

      def initialize(limit)
        @limit = limit
      end

      def process(data)
        data.count < @limit
      end
      
    end
  end
end