module AutomaticsEmails
  class Manager

    TYPE_ACCESS_LOST_IN_THREAD = :access_lost_in_thread

    RULES = {
        TYPE_ACCESS_LOST_IN_THREAD: {
          
        }
    }

    def initialize(messages_thread)
      @messages_thread = messages_thread
    end

    def send(email_type)
      @email_type = email_type

      if can_send?
        deliver
        true
      else
        false
      end
    end

    private

    def can_send?
      
    end

    def deliver
      
    end
  end
end