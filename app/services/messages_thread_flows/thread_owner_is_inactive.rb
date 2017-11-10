module MessagesThreadFlows
  class ThreadOwnerIsInactive

    attr_accessor :thread_account_association_manager, :messages_thread

    def initialize(thread_account_association_manager, flow=:import_emails)
      @thread_account_association_manager = thread_account_association_manager
      @messages_thread = @thread_account_association_manager.messages_thread
      @flow = flow
    end

    def trigger
      enter
    end

    private

    def enter
      next_account = compute_next_viable_candidate

      if next_account.present?
        associate_thread_to_new_account(next_account)
        reset_auto_follow_up_if_needed
      else
        no_viable_candidate_found_actions
      end
    end

    def must_enter
      @messages_thread.check_if_owner_inactive
    end

    def associate_thread_to_new_account(new_account)
      @messages_thread.update(account_email: new_account.email, account_name: new_account.usage_name)
    end

    def no_viable_candidate_found_actions
      @messages_thread.reset_auto_follow_up

      # At this point the account owner of the thread is the unsubbed user
      if @flow == :import_emails
        last_message_recipients = @thread_account_association_manager.recipients_emails_for_last_message.values.flatten
        last_message = @messages_thread.messages.sort_by{|m| m.updated_at}.last

        client_emails_in_recipients = last_message_recipients & @messages_thread.account.all_emails

        unless @messages_thread.account_request_auto_email_sent
          if  client_emails_in_recipients.present?
            send_notice_email_to_old_client(last_message, client_emails_in_recipients.first)
          else
            send_notice_email_to_interlocutor(last_message, @messages_thread.account_email)
          end
        end
      end

      @messages_thread.archive
    end

    def compute_next_viable_candidate
      continue_search = @messages_thread.accounts_candidates_primary_list.present?
      next_account = nil

      while continue_search
        next_account_candidate_email = @messages_thread.accounts_candidates_primary_list.shift
        continue_search = @messages_thread.accounts_candidates_primary_list.present?

        if next_account_candidate_email.present?
          next_account = Account.create_from_email(next_account_candidate_email, {accounts_cache: @accounts_cache})

          if next_account.subscribed
            continue_search = false
          else
            next_account = nil
          end
        end
      end

      @messages_thread.update(accounts_candidates_primary_list: @messages_thread.accounts_candidates_primary_list)
      next_account
    end

    def reset_auto_follow_up_if_needed
      unless @messages_thread.clients.any?{|acc| acc.auto_follow_up_enabled}
        @messages_thread.reset_auto_follow_up
      end
    end

    def send_notice_email_to_old_client(last_message, email_to_send_to)
      account = Account.create_from_email(email_to_send_to)

      AutoReplyAccountNoticeWorker.enqueue(last_message.id, 'account_deactivated.client', email_to_send_to, account.try(:usage_name))
      #last_message.send_account_notice_email('account_deactivated.client', email_to_send_to)
    end

    def send_notice_email_to_interlocutor(last_message, client_email)
      account = Account.create_from_email(client_email)

      AutoReplyAccountNoticeWorker.enqueue(last_message.id, 'account_deactivated.interlocutor', nil, account.try(:usage_name))
      #last_message.send_account_notice_email('account_deactivated.interlocutor')
    end

  end
end