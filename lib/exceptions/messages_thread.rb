module Exceptions
  module MessagesThread

    class NoMessageError < StandardError

      attr_reader :messages_thread
      def initialize(server_thread_id)
        @server_thread_id = server_thread_id
      end

      def message
        "No messages have been found for this messages thread, it should not happen. Check the email server for the thread #{@server_thread_id}"
      end

      def to_s
        "#{message} #{super}"
      end
    end
  end
  
  
end