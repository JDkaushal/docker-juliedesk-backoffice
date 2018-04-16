module AutomaticProcessing

  class EmailDeliverer
    include TemplateGeneratorHelper
    attr_reader :data_holder

    def initialize(data_holder)
      @data_holder = data_holder
    end

    def deliver(params = {})
      if params[:is_error]
        if params[:ai_processing_error]
          deliver_error_message(params[:exception], AutomaticProcessing::Exceptions::AI_PROCESSING_ERROR)
        else
          deliver_error_message(params[:exception], AutomaticProcessing::Exceptions::GENERIC_ERROR)
        end

      else
        deliver_message
      end
    end

    private

    def deliver_error_message(exception, error_type)
      messages = @data_holder.get_messages_thread.re_import

      initial_message = messages.find{|m| m.id == @data_holder.get_message.id}

      EmailServer.deliver_message({
                                    subject: @data_holder.get_messages_thread_subject,
                                    from: @data_holder.get_julie_alias_from,
                                    to: initial_message.server_message['from'],
                                    cc: '',
                                    html: get_error_body(error_type),
                                    quote_replied_message: false,
                                    quote_forward_message: false,
                                    reply_to_message_id: @data_holder.get_server_message_id
                                  })
    end

    def get_error_body(error_type)
      if error_type == AutomaticProcessing::Exceptions::AI_PROCESSING_ERROR
        get_ai_processing_error_template({})
      else
        get_generic_error_template({})
      end
    end

    def deliver_message
      initial_recipients = @data_holder.get_message_initial_recipients

      recipients_to = initial_recipients[:to]
      recipients_cc = initial_recipients[:cc]

      if @data_holder.get_julie_action_nature == JulieAction::JD_ACTION_WAIT_FOR_CONTACT
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