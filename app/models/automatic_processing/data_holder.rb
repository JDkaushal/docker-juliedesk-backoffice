module AutomaticProcessing

  class DataHolder
    include ApplicationHelper

    class DataHolderError < StandardError
    end

    class MessageMissingError < DataHolderError
    end

    class NoMessageClassificationYetError < DataHolderError
    end

    class NoJulieActionYetError < DataHolderError
    end

    attr_reader :messages_thread, :message, :message_classification, :julie_action

    def initialize(incoming_message)
      raise MessageMissingError.new("No message specified") if incoming_message.blank?

      @message = incoming_message
      @message.populate_single_server_message
      @messages_thread = @message.messages_thread
    end

    def get_message
      @message
    end

    def get_messages_thread
      @messages_thread
    end

    def get_message_classification
      raise AutomaticProcessing::DataHolder::NoMessageClassificationYetError unless @message_classification.present?
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

    def get_message_server_id
      @message_server_id ||= get_message.server_message_id
    end

    def get_message_id
      @message_id ||= get_message.id
    end

    def get_current_classification
      @current_classification ||= get_message_classification.classification
    end

    def get_message_classification_duration
      @message_classification_duration ||= get_message_classification.duration
    end

    def get_message_classification_identifier
      @message_classification_identifier ||= get_message_classification.identifier
    end

    def get_message_classification_main_interpretation
      @classification_main_interpretation ||= (get_message.main_message_interpretation.try(:json_response) || {})
    end

    def get_message_classification_raw_constraints
      @message_classification_raw_constraints ||= get_message_classification.constraints_data
    end

    def get_message_classification_date_times
      @message_classification_date_times ||= JSON.parse(get_message_classification.date_times || '[]')
    end

    def get_message_classification_location
      @message_classification_location ||= get_message_classification.location
    end

    def get_message_classification_timezone
      @message_classification_timezone ||= get_message_classification.timezone
    end

    def get_last_dates_to_verify
      @last_dates_to_verify ||= (get_messages_thread.get_dates_to_verify.try(:[], :last_proposition) || [])
    end

    def get_message_classification_summary
      @message_classification_summary ||= get_message_classification.summary
    end

    def get_message_classification_notes
      @message_classification_notes ||= get_message_classification.notes
    end

    def get_message_classification_location
      @message_classification_location ||= get_message_classification.location
    end

    def get_thread_computed_data
      @thread_computed_data ||= get_messages_thread.computed_data
    end

    def get_message_classification_verify_dates_by_ai
      @message_classification_verify_dates_by_ai ||= get_message_classification.verify_dates_by_ai
    end

    def get_thread_event_data
      @thread_event_data ||= get_messages_thread.event_data
    end

    def get_current_locale
      @current_locale ||= get_message_classification.locale
    end

    def get_messages_thread_subject
      @messages_thread_subject ||= get_messages_thread.subject
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

    def search_attendees_in_present(emails)
      get_present_attendees.select{|a| emails.include?(a[:email].downcase)}
    end

    def get_present_attendees
      @present_attendees ||= get_attendees.select{|a| a['isPresent']}
    end

    def get_message_classification_computed_thread_status
      @message_classification_computed_thread_status ||= get_message_classification.computed_thread_status
    end

    def get_message_classification_asap_constraint
      @message_classification_asap_constraint ||= get_message_classification.asap_constraint
    end

    def get_julie_action_text
      @julie_action_text ||= get_julie_action.text
    end

    def get_julie_action_html
      @julie_action_html ||= get_julie_action.html
    end

    def get_thread_julie_alias
      @thread_julie_alias ||= get_messages_thread.julie_alias
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
      return @email_html_body unless @email_html_body.blank?

      html_content = get_julie_action_html
      footer_and_signature = get_julie_alias_footer_and_signature

      if html_content.present?
          html_doc      = Nokogiri::HTML(html_content)

          # Footer
          text_footer_html    = text_to_html(footer_and_signature[:text_footer])
          text_footer         = Nokogiri::HTML::DocumentFragment.parse(text_footer_html)

          # Signature
          signature     = Nokogiri::HTML::DocumentFragment.parse(footer_and_signature[:html_signature])

          html_doc.css('body').first.add_child(text_footer)
          html_doc.css('body').first.add_child(signature)
          html_doc.css('body').inner_html
      else
        text_content          = get_julie_action_text
        footer_and_signature  = get_julie_alias_footer_and_signature
        text_in_email         = "#{text_content}#{footer_and_signature[:text_footer]}"
        @email_html_body      = text_to_html(text_in_email) + footer_and_signature[:html_signature].html_safe
      end
    end

    def get_thread_owner_main_email
      @thread_owner_main_email ||= get_messages_thread.account_email
    end

    def get_thread_owner_account
      @thread_owner_account ||= get_messages_thread.account
    end

    def get_thread_owner_account_email
      @thread_owner_account_email ||= get_thread_owner_account.email
    end

    def get_thread_owner_default_timezone
      @thread_owner_default_timezone ||= get_thread_owner_account.default_timezone_id
    end

    def get_appointments
      @appointments ||= get_thread_owner_account.appointments
    end

    def get_addresses
      @addresses ||= get_thread_owner_account.addresses
    end

    def get_last_suggest_dates_classification
      @last_suggest_dates_classification ||= get_messages_thread.messages.map(&:message_classifications).flatten.select{|mc| mc.classification == MessageClassification::ASK_DATE_SUGGESTIONS}.sort_by(&:created_at).first
    end

    def get_all_available_meeting_rooms
      @all_available_meeting_rooms ||= get_addresses.map{|address| address['available_meeting_rooms']}.flatten
    end

    def get_address
      @current_address ||= get_addresses.find{|address| address['address'] == get_message_classification.location}
    end

    def get_appointment
      @current_appointment ||= get_appointments.find{|appointment| appointment['kind'] == get_message_classification.appointment_nature}
    end

    def get_client_names
      @client_names ||= get_attendees.select{|att| att['isPresent'] && att['isClient']}.map do |att|
        att['usageName']
      end
    end

    def get_attendees_count
      @attendees_count ||= get_present_attendees.size
    end

    def get_present_attendees_usage_names
      @present_attendees_usage_names ||= get_attendees.select{|att| att['isPresent'] && att['isClient']}.map do |att|
        {
          name: att['usageName']
        }
      end
    end

    def is_appointment_virtual?
      get_appointment['appointment_kind_hash']['is_virtual']
    end

    def get_attendees
      @attendees ||= JSON.parse(get_message_classification.attendees).map(&:with_indifferent_access)
    end

    def get_julie_action_nature
      @julie_action_nature ||= get_julie_action.action_nature
    end

    def get_message_classification_booked_rooms_details
      @message_classification_booked_rooms_details ||= get_message_classification.booked_rooms_details
    end

    def get_meeting_room_details(room_email)
      room_details = {}

      get_addresses.find do |addr|
        room_infos = addr['available_meeting_rooms'].find{|room| room['id'] == room_email}

        if room_infos.present?
          room_details = room_infos
          room_details['location'] = addr['address']
          true
        else
          false
        end
      end

      room_details
    end
  end
end