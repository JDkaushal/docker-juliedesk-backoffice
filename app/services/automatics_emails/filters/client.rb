module AutomaticsEmails
  module Filters

    class Client < Base

      attr_reader :window

      def initialize(auto_email_type, window)
        super(auto_email_type)
        @window = window
      end

      def filter(messages_thread)
        client_email = messages_thread.account_email

        Message.joins(:messages_thread).where('messages_threads.account_email = ?', client_email).where(auto_email_kind: @auto_email_type).where('messages.updated_at >= ?', Time.now - @window)
      end

    end
  end
end