module AccountFlows

  class ClientUnsubscribed

    THREAD_SCHEDULING_STATUSES = [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT]

    def initialize(account_email)
      @account_email = account_email
      @account_messages_threads = []
    end

    def trigger
      enter
    end

    private

    def enter
      reset_auto_follow_up
      inform_client_on_needed_threads
    end

    def reset_auto_follow_up
      get_threads_with_auto_follow_up_set.update_all(follow_up_reminder_date: nil)
    end

    def inform_client_on_needed_threads
      threads = get_account_scheduling_threads
      threads.each(&:send_account_gone_unsubscribe_email)

      julie_aliases = JulieAlias.all
      julie_aliases_emails = julie_aliases.map(&:email)
      accounts_cache = Account.accounts_cache(mode: "light")

      account_association_data_holder = ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, julie_aliases_emails)

      threads.each do |mt|
        thread_account_association_manager = ThreadAccountAssociation::Manager.new(
            data_holder: account_association_data_holder,
            messages_thread: mt,
            server_thread: mt.server_thread
        )

        MessagesThreadFlows::ThreadOwnerIsInactive.new(thread_account_association_manager, :client_unsubscribed).trigger
      end
    end

    def get_threads_with_auto_follow_up_set
      MessagesThread.select(:id, :follow_up_reminder_date, :account_email).where(account_email: @account_email).where('follow_up_reminder_date IS NOT NULL')
    end

    def get_account_scheduling_threads
      fields = [:id, :status, :account_email, :server_thread_id, :subject, :account_request_auto_email_sent, :accounts_candidates_primary_list, :clients_in_recipients, :updated_at]
      threads = MessagesThread.includes(:messages).select(fields).where(account_email: @account_email, status: THREAD_SCHEDULING_STATUSES)
      threads.all.select do |thread|
        last_message = thread.get_last_message
        last_message && last_message.received_at > 1.month.ago
      end
    end


  end
end