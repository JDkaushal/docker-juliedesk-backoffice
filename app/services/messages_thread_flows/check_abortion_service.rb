module MessagesThreadFlows
  class CheckAbortionService

    def check(now = nil)
      now ||= DateTime.now

      MessagesThread.currently_scheduling.includes(messages: {message_classifications: :julie_action}, operator_actions: {}).each do |messages_thread|
        messages_thread.check_abortion(now)
      end
    end
  end
end
