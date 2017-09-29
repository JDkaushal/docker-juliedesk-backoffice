module AutomaticsEmails
  class Manager
    include Rules

    def initialize(message)
      @message = message
      @messages_thread = @message.messages_thread
    end

    def send(email_type, translation_params, email_to_recipient = nil)
      @email_type = email_type
      @translation_params = translation_params
      @email_to_recipient = email_to_recipient

      if can_send?
        deliver
        true
      else
        false
      end
    end

    private

    def can_send?
      apply_filters
    end

    def apply_filters
      select_rules.all? do |rule|
        filtered_data = rule[:filter].filter(@messages_thread)
        rule[:conditions].all? do |condition|
          condition.process(filtered_data)
        end
      end
    end

    def select_rules
      RULES.with_indifferent_access[@email_type]
    end

    def deliver
      @message.send_auto_email(@email_type, @translation_params, @email_to_recipient)
    end
  end
end