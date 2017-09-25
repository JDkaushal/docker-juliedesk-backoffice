module AutomaticsEmails
  module Filters

    class Thread < Base

      def initialize(auto_email_type, window)
        super(auto_email_type)
        @window = window
      end

      def filter(messages_thread)
        messages_thread.messages.where(auto_email_kind: @auto_email_type).where('updated_at >= ?', Time.now - @window)
      end

    end
  end
end