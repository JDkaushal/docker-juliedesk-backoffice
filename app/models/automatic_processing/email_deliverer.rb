module AutomaticProcessing

  class EmailDeliverer

    attr_reader :data_holder

    def initialize(data_holder)
      @data_holder = data_holder
    end

    def deliver
      deliver_message
    end

    private

    def deliver_message
      initial_recipients = @data_holder.get_message_initial_recipients

      recipients_to = initial_recipients[:to]
      recipients_cc = initial_recipients[:cc]

      if self.action_nature == JD_ACTION_WAIT_FOR_CONTACT
        recipients_to = [initial_recipients[:client]]
        recipients_cc = []
      end

      email_server_response = EmailServer.deliver_message({
                                                            subject: @data_holder.get_messages_thread_subject,
                                                            from: @data_holder.get_julie_alias_from,
                                                            to: recipients_to.join(", "),
                                                            cc: recipients_cc.join(", "),
                                                            html: @data_holder.get_email_html_body,
                                                            quote_replied_message: @data_holder.get_should_quote_previous_email,
                                                            quote_forward_message: false,
                                                            reply_to_message_id: @data_holder.get_server_message_id
                                                          })

      @data_holder.get_julie_action.update({
        server_message_id: email_server_response['id'],
        done: true
      })
    end

    
  end
end