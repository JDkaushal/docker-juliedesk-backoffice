module AutomaticProcessing
  module ClassificationsFlows

    class Base

      def post_classification_actions
        raise NotImplementedError.new("Please define #{__method__} on #{self.class.name}")
      end

    end

  end


end