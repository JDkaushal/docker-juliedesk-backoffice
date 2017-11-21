module LinkedAttendees
  class Manager

    attr_reader :messages_thread, :accounts_cache

    FETCH_URL = ENV['JULIEDESK_APP_BASE_PATH'] + '/api/v1/linked_attendees/extract'

    def initialize(messages_thread, accounts_cache)
      @messages_thread = messages_thread
      @accounts_cache = accounts_cache
    end

    def fetch(forced_emails_to_check = nil)
      fetch_call(forced_emails_to_check)
    end

    private

    def fetch_call(forced_emails_to_check)
      client = HTTP.auth(ENV['JULIEDESK_APP_API_KEY'])

      attendees_to_check = if forced_emails_to_check.present?
                             forced_emails_to_check
                           else
                             computed_data_only_attendees = @messages_thread.computed_data_only_attendees[:attendees]

                              if computed_data_only_attendees.present?
                                computed_data_only_attendees.select{|o| o["isPresent"] == "true" && o["isThreadOwner"] == "false"}.map{|m| m["email"]}
                              else
                                @messages_thread.computed_recipients
                              end
                           end

      # Separate clients from non clients in a beautiful and magnificent way
      recipients = attendees_to_check.partition {|r_email| Account.find_active_and_configured_account_email(r_email, {accounts_cache: @accounts_cache}).present?}

      #clients_recipients = recipients[0].map{|client_recipient| Account.find_account_email(client_recipient, {accounts_cache: @accounts_cache})}
      #clients_recipients = [@messages_thread.account_email]
      clients_recipients = @messages_thread.get_clients_with_linked_attendees_enabled.map(&:email)

      result = {}
      if recipients[1].present? # Don't call if no other attendees than clients
        # We send the main emails of the clients (in case these were aliases)
        response = client.post(FETCH_URL, json: {clients_emails: clients_recipients, attendees_emails: recipients[1]})
        if response.code == 200
          result = response.parse
        end
      end

      result
    end
  end
end
