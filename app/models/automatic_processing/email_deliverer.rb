module AutomaticProcessing

  class EmailDeliverer
    include TemplateGeneratorHelper
    attr_reader :data_holder

    def initialize(data_holder)
      @data_holder = data_holder
    end

    def deliver(params = {})
      return deliver_error_message(params[:exception]) if params[:is_error]

      deliver_message
    end

    private

    def deliver_error_message(exception)
      messages = @data_holder.get_messages_thread.re_import

      initial_message = messages.find{|m| m.id == @data_holder.get_message.id}
      message_content = get_error_body(exception)

      return nil if message_content.nil?

      EmailServer.deliver_message({
                                    subject: @data_holder.get_messages_thread_subject,
                                    from: @data_holder.get_julie_alias_from,
                                    to: initial_message.server_message['from'],
                                    cc: '',
                                    html: message_content,
                                    quote_replied_message: false,
                                    quote_forward_message: false,
                                    reply_to_message_id: @data_holder.get_server_message_id
                                  })
    end

    def get_error_body(exception)
      if exception.is_a?(AutomaticProcessing::Exceptions::CommandLineNotUnderstood)
        get_command_line_not_understood_template({ reasons: exception.reasons, contact_email: "hello@juliedesk.com" })
      elsif exception.is_a?(AutomaticProcessing::Exceptions::UnprocessableRequest)
        get_ai_unprocessable_request_error_template({ contact_email: "hello@juliedesk.com" })
      elsif exception.is_a?(AutomaticProcessing::Exceptions::ConscienceDatesSuggestionNotEnoughSuggestionsError)
        get_no_available_slot_template({form_link_en: ENV['SLASH_SATISFACTION_FORM_EN_URL'], form_link_fr: ENV['SLASH_SATISFACTION_FORM_FR_URL']})
      else
        nil
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