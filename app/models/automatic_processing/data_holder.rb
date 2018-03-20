module AutomaticProcessing

  class DataHolder

    class DataHolderError < StandardError
    end

    class NoMessageClassifictionYetError < DataHolderError
    end

    class NoJulieActionYetError < DataHolderError
    end

    attr_reader :messages_thread, :message, :message_classification, :julie_action

    def initialize(incoming_message)
      @message = incoming_message
      @messages_thread = @message.messages_thread
    end

    def get_message
      @message
    end

    def get_messages_thread
      @messages_thread
    end

    def get_message_classification
      raise AutomaticProcessing::DataHolder::NoMessageClassifictionYetError.new unless @message_classification.present?
      @message_classification
    end

    def set_message_classification(message_classification)
      @message_classification = message_classification
    end

    def set_julie_action(julie_action)
      @julie_action = julie_action
    end

    def get_julie_action
      raise AutomaticProcessing::DataHolder::NoJulieActionYetError.new unless @julie_action.present?
      @julie_action
    end

    def get_current_classification
      get_message_classification.classification
    end

    def get_current_locale
      @current_locale ||= get_message_classification.locale
    end

    def get_messages_thread_subject
      @messages_thread_subject ||= @messages_thread.subject
    end

    def get_server_message_id
      @server_message_id ||= @message.server_message_id
    end

    def get_message_initial_recipients_only_reply_all
      @message_initial_recipients_only_reply_all ||= @message.initial_recipients({
                                                                                    only_reply_all: true,
                                                                                    contact_emails: get_messages_thread_contacts,
                                                                                    present_attendees: get_present_attendees
                                                                                })
    end

    def get_message_initial_recipients
      @message_initial_recipients ||= @message.initial_recipients({
                                                                    contact_emails: get_messages_thread_contacts,
                                                                    present_attendees: get_present_attendees
                                                                  })
    end

    def get_messages_thread_contacts
      @messages_thread_contacts ||= MessagesThread.contacts({server_messages_to_look: [@message.server_message]}).map { |c| c[:email].try(:downcase) }
    end

    def get_present_attendees
      @present_attendees ||= JSON.parse(get_message_classification.attendees).select{|a| a['isPresent'] == 'true'}
    end

    def get_message_classification_computed_thread_status
      @message_classification_computed_thread_status ||= get_message_classification.computed_thread_status
    end

    def get_julie_action_text
      @julie_action_text ||= get_julie_action.text
    end

    def get_thread_julie_alias
      @thread_julie_alias ||= @messages_thread.julie_alias
    end

    def get_julie_alias_footer_and_signature
      @julie_alias_footer_and_signature ||= get_thread_julie_alias.generate_footer_and_signature(get_current_locale)
    end

    def get_julie_alias_from
      @julie_alias_from ||= get_thread_julie_alias.generate_from
    end

    def get_should_quote_previous_email
      initial_recipients = get_message_initial_recipients
      initial_recipients_only_reply_all = get_message_initial_recipients_only_reply_all

      @should_quote_previous_email ||= ((initial_recipients[:to] + initial_recipients[:cc]) - initial_recipients_only_reply_all[:to] - initial_recipients_only_reply_all[:cc]).length == 0
    end

    def get_email_html_body
      if @email_html_body.blank?
        footer_and_signature = get_julie_alias_footer_and_signature
        text_in_email = "#{@data_holder.get_julie_action_text}#{@data_holder.get_julie_alias_footer_and_signature[:text_footer]}"
        @email_html_body = text_to_html(text_in_email) + footer_and_signature[:html_signature].html_safe
      else
        @email_html_body
      end
    end

    def get_thread_owner_account
      @thread_owner_account ||= get_messages_thread.account
    end

    def get_appointments
      @appointments ||= get_thread_owner_account.appointments
    end

    def get_addresses
      @addresses ||= get_thread_owner_account.addresses
    end

    def get_apppointment
      @current_appointment ||= get_appointments.find{|appointment| appointment['label'] == get_message_classification.appointment_nature}
    end

    def get_client_names
      @client_names ||= get_attendees.select{|att| att['isPresent'] == 'true' && att['isClient'] == 'true'}.map do |att|
        att['usageName']
      end
    end

    def get_present_attendees
      @present_attendees ||= get_attendees.select{|att| att['isPresent'] == 'true' && att['isClient'] != 'true'}.map do |att|
        {
          name: att['usageName']
        }
      end
    end

    def get_attendees
      @attendees ||= JSON.parse(get_message_classification.attendees)
    end
  end
end