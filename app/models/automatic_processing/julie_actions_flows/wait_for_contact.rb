module AutomaticProcessing
  module JulieActionsFlows

    class WaitForContact < Base
      include CommonMethods

      def trigger
        generate_template
      end

      private

      def generate_template
        @julie_action.text = get_wait_for_contact_template({
                                                               locale: @data_holder.get_current_locale
                                                           })
      end
    end
  end
end