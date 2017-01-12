module ThreadAccountAssociation
  class DataHolder

    attr_reader :last_3_weeks_threads_attendees,
                :clients_emails,
                :accounts_cache,
                :julie_alias_emails,
                :julie_aliases,
                :julie_aliases_company_association_cache

    def initialize(accounts_cache, julie_aliases, julie_alias_emails)
      if accounts_cache.blank?
        raise Exceptions::ThreadAccountAssociation::NoAccountsCacheProvidedError.new
      end

      if julie_alias_emails.blank?
        raise Exceptions::ThreadAccountAssociation::NoJulieAliasEmailsCacheProvidedError.new
      end

      if julie_aliases.blank?
        raise Exceptions::ThreadAccountAssociation::NoJulieAliasesCacheProvidedError.new
      end

      @accounts_cache = accounts_cache
      @julie_alias_emails = julie_alias_emails
      @julie_aliases = julie_aliases
    end

    def get_last_3_weeks_threads_recipients(except_messages_thread_id)
      if @last_3_weeks_threads_attendees.blank?
        @last_3_weeks_threads_attendees = MessagesThread.select(:computed_recipients).where('id != ? AND updated_at >= ?', except_messages_thread_id, Time.now - 3.weeks).map(&:computed_recipients)
        @last_3_weeks_threads_attendees.flatten!
        @last_3_weeks_threads_attendees.uniq!
      end
      @last_3_weeks_threads_attendees
    end

    def get_clients_emails
      @client_emails ||= @accounts_cache.inject([]){|emails, c| c=c[1]; current_emails = c["email_aliases"] << c["email"] ; emails += current_emails; }.map(&:downcase).reject{|e| e == ''}
    end

    def get_julie_aliases_company_association_cache
      @julie_aliases_company_association_cache ||= JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get('julie_aliases_company_association') || '[]')
    end

  end
end