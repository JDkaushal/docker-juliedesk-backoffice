module AutomaticProcessing
  module Flows

    class WaitForContact < Base

      def post_classification_actions
        [:deliver_email, :archive_thread]
      end
    end
  end
end