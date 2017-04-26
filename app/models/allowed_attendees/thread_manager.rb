module AllowedAttendees
  class ThreadManager

    attr_reader :messages_thread

    def initialize(messages_thread)
      @messages_thread = messages_thread
    end

    def compute_allowed_attendees
      Set.new(extract_from_thread_owner + extract_from_clients_current_notes + extract_from_accounts_candidates + extract_from_messages + extract_from_current_attendees).to_a.compact
    end

    private

    def emails_regexp
      @emails_regex ||= AllowedAttendees::RegexpManager.email_regexp
    end

    def extract_from_messages
      @messages_thread.messages.map(&:allowed_attendees).flatten
    end

    def extract_from_current_attendees
      current_attendees = []
      computed_data = @messages_thread.computed_data

      if computed_data.present?
        current_attendees = computed_data[:attendees].map{|att| att['email']}
      end

      current_attendees
    end

    def extract_from_thread_owner
      account = @messages_thread.account
      owner_emails = []

      if account.present?
        owner_emails.push(account.email)
        owner_emails += account.email_aliases
      end

      owner_emails.flatten
    end

    def extract_from_accounts_candidates
      @messages_thread.accounts_candidates
    end

    def extract_from_clients_current_notes
      clients_current_notes = @messages_thread.clients.map{|c| c.current_notes}

      current_notes_aggregated = if clients_current_notes.present?
        clients_current_notes.join(' ')
      else
        ''
      end

      current_notes_aggregated.scan(emails_regexp)
    end
  end
end