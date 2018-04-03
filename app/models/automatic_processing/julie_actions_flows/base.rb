module AutomaticProcessing
  module JulieActionsFlows

    class Base
      attr_reader :julie_action, :data_holder

      def initialize(julie_action)
        @julie_action = julie_action
        initialize_data_holder
      end
      
      private

      def initialize_data_holder
        @data_holder = AutomaticProcessing::DataHolder.new(@julie_action.message_classification.message)
        @data_holder.set_message_classification(@julie_action.message_classification)
        @data_holder.set_julie_action(@julie_action)
      end

    end
  end
end