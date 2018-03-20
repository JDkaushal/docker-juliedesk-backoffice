module AutomaticProcessing
  module Flows

    class Base

      def post_classification_actions
        raise NotImplementedError.new("Please define #{__method__} on #{self.class.name}")
      end

    end

  end


end