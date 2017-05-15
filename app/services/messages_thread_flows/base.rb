module MessagesThreadFlows
  class Base
    attr_accessor :messages_thread

    def initialize(messages_thread)
      @messages_thread = messages_thread
    end
  end
end