module AutomaticProcessing
  module JulieActionsFlows

    class Base
      attr_reader :julie_action, :data_holder

      def initialize(julie_action)
        @julie_action = julie_action
        @data_holder = @julie_action.data_holder
      end

    end
  end
end