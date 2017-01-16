module ThreadAccountAssociation
  class Manager

    # The *messages_thread* variable is an instance of MessagesThread, can be nil if a new MessagesThread needs to be created
    # The *server_thread* variable is a hash holding all the informations of a thread. Coming from the email server
    attr_reader :data_holder,
                :messages_thread,
                :server_thread,
                :thread_messages_bodies,
                :first_thread_message,

                :recipients_emails,
                :used_julie,
                :clients_found_in_bodies,
                :users_associated_with_julie_alias

    def initialize(params)
      @data_holder = params[:data_holder]
      @messages_thread = params[:messages_thread]
      @server_thread = params[:server_thread]
      @recipients_emails = {}

      @logger = Rails.logger
    end

    def compute_association
      compute_recipients_emails
      compute_accounts_candidates(@recipients_emails)

      process_association
    end

    def compute_accounts_candidates(recipients)
      #compute_recipients_emails

      accounts_candidates_in_bodies = []

      if using_julie_alias
        @logger.debug("-- Entrering flow => using_julie_alias --")
        # used_julie_alias = get_used_julie.email
        # users_associated_with_julie_alias = get_company_users(@data_holder.get_julie_aliases_company_association_cache[used_julie_alias])
        #accounts_candidates_in_bodies = lookup_clients_with_julie_alias(users_associated_with_julie_alias).map{ |u| u['email'] }
        accounts_candidates_in_bodies = find_clients_with_julie_alias
      else
        @logger.debug("-- Entrering flow => using main julie --")
        accounts_candidates_in_bodies = find_clients_with_main_julie[:association_candidates]
      end

      accounts_candidates = accounts_candidates_in_bodies += get_accounts_emails(recipients)
      if accounts_candidates.present?
        @messages_thread.update(accounts_candidates: accounts_candidates.to_a.uniq)
      end
    end
    
    private

    def get_server_messages
      #@server_messages ||= @server_thread['messages'].reject{|m| m['from_me']}
      @server_messages ||= @server_thread['messages']
    end

    def get_thread_emails_bodies
      @thread_messages_bodies ||= get_server_messages.map{|m| m['text']}.join.downcase
    end

    def get_first_thread_message
      if @first_thread_message.blank?
        @first_thread_message = get_server_messages.sort_by{|m| DateTime.parse(m['date'])}.first

        # if @first_thread_message.blank?
        #   raise Exceptions::MessagesThread::NoMessageError.new(@messages_thread)
        # end
      end
      @first_thread_message
    end

    def get_recipients_from_all_messages
      @recipients_from_all_messages ||= {
        to: sanitize_recipients_array(get_server_messages.map{|m| m['to']}),
        from: sanitize_recipients_array(get_server_messages.map{|m| m['from']}),
        cc: sanitize_recipients_array(get_server_messages.map{|m| m['cc']})
      }

    end

    def sanitize_recipients_array(array)
      array.uniq!
      array.compact!
      array
    end

    def compute_recipients_emails
      @recipients_emails[:from] = extract_recipients_emails(get_recipients_from_all_messages[:from]) - @data_holder.julie_alias_emails
      @recipients_emails[:to] = extract_recipients_emails(get_recipients_from_all_messages[:to]) - @data_holder.julie_alias_emails
      @recipients_emails[:cc] = extract_recipients_emails(get_recipients_from_all_messages[:cc]) - @data_holder.julie_alias_emails

      @logger.debug("-- Recipients found => #{@recipients_emails.inspect} --")
    end

    def process_association
      @logger.debug("-- Entering process_association for thread #{@messages_thread.id} --")

      clients_emails = find_clients_in_recipients
      try_to_merge = false
      result = {}

      @logger.debug("-- clients emails founds: #{clients_emails.inspect} --")

      # We take the first client we find as the thread owner
      if clients_emails.present?
        @logger.debug("-- Entrering flow => clients emails found in recipients --")
        @logger.debug("-- associating #{clients_emails[0]} --")
        result = associate_client_to_thread(clients_emails[0])
      else
        if using_julie_alias && @users_associated_with_julie_alias.present? && @users_associated_with_julie_alias.size == 1
          @logger.debug("-- Entrering flow => Associating #{@clients_found_in_bodies.first.inspect} --")
          result = associate_client_to_thread(@users_associated_with_julie_alias.first['email'])

          # When no clients in recipients, use Julie method
          # if using_julie_alias
          #   @logger.debug("-- Entrering flow => using_julie_alias --")
          #   result = find_clients_with_julie_alias
          # else
          #   @logger.debug("-- Entrering flow => using main julie --")
          #   result = find_clients_with_main_julie
          # end
        end
      end

      # If we could not find a proper account to associate to the thread
      if !result[:associated] && @messages_thread.accounts_candidates.blank?
        @logger.debug("-- Entrering flow => Thread still not associated --")

        # if @messages_thread.accounts_candidates.present?
        #   @logger.debug("-- Found some association candidates => #{result[:association_candidates].inspect} --")
        #   @logger.debug("-- Associating possible candidates to thread --")
        #   @messages_thread.update(accounts_candidates: result[:association_candidates].to_a)
        # else
        @logger.debug("-- Trying to find merging candidate... --")

        # If no candidates found by any means in the current thread, we will check if any of the recipients in the thread is present in a thread from the last 3 weeks
        try_to_merge = check_possible_merging
        @logger.debug("-- will try to merge => #{try_to_merge} --")
        @logger.debug("-- automatic email already sent => #{@messages_thread.account_request_auto_email_sent} --")

        if !try_to_merge && !@messages_thread.account_request_auto_email_sent
          @logger.debug("-- Sending automatic request account then archiving --")
          send_account_request_email
          @messages_thread.archive
        end
      end

      # If we could not find any recipients in the last 3 weeks threads
      # We will send an automatic email to the sender asking him to precise its demand then archive the thread
      # We do this only if we didn't already send it previously

      @logger.debug("-- Final result => #{result.inspect} --")

      result
    end

    def send_account_request_email
      first_message = get_first_thread_message

      if first_message
        message = Message.find_by(server_message_id: first_message['id'])
        AutoReplyTargetAccountPrecisionsWorker.enqueue(message.id)
      end
    end

    def associate_client_to_thread(account_email)
      account = Account.create_from_email(account_email, {accounts_cache: @data_holder.accounts_cache})

      @messages_thread.update_attributes({
                                          account_email: account_email,
                                          account_name: account.try(:usage_name)
                                        })

      {associated: true}
    end

    def get_used_julie
      @used_julie ||= @messages_thread.julie_alias(julie_aliases: @data_holder.julie_aliases)
    end

    def using_julie_alias
      used_julie = get_used_julie
      used_julie && used_julie.email != 'julie@juliedesk.com'
    end

    def find_clients_with_main_julie
      @found_clients_in_bodies = look_up_clients_in_emails_bodies(@data_holder.get_clients_emails)

      {associated: false, association_candidates: @found_clients_in_bodies}
    end

    def lookup_clients_with_julie_alias(users_associated_with_julie_alias)
      found_first_names = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['firstName'].try(:downcase)}.compact)
      found_last_names = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['lastName'].try(:downcase)}.compact)
      found_emails = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['email'].try(:downcase)}.compact)

      @clients_found_in_bodies = Set.new
      @clients_found_in_bodies.merge(users_associated_with_julie_alias.select{ |u| found_first_names.include?(u['firstName'].try(:downcase)) })
      @clients_found_in_bodies.merge(users_associated_with_julie_alias.select{ |u| found_last_names.include?(u['lastName'].try(:downcase)) })
      @clients_found_in_bodies.merge(users_associated_with_julie_alias.select{ |u| found_emails.include?(u['email'].try(:downcase)) })

      @clients_found_in_bodies = @clients_found_in_bodies.map{ |u| u['email']}
    end

    def find_clients_with_julie_alias
      # used_julie_alias = get_used_julie.email
      # users_associated_with_julie_alias = get_company_users(@data_holder.get_julie_aliases_company_association_cache[used_julie_alias])
      # result = {}
      #
      # if users_associated_with_julie_alias.size == 1
      #   result = associate_client_to_thread(users_associated_with_julie_alias.first['email'])
      # else
      #   # found_first_names = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['firstName'].try(:downcase)}.compact)
      #   # found_last_names = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['lastName'].try(:downcase)}.compact)
      #   # found_emails = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['email'].try(:downcase)}.compact)
      #   #
      #   # association_candidates = Set.new
      #   # association_candidates.merge(users_associated_with_julie_alias.select{ |u| found_first_names.include?(u['firstName'].try(:downcase)) })
      #   # association_candidates.merge(users_associated_with_julie_alias.select{ |u| found_last_names.include?(u['lastName'].try(:downcase)) })
      #   # association_candidates.merge(users_associated_with_julie_alias.select{ |u| found_emails.include?(u['email'].try(:downcase)) })
      #   association_candidates = lookup_clients_with_julie_alias(users_associated_with_julie_alias)
      #   result = { associated: false, association_candidates: association_candidates }
      # end
      #
      # result

      used_julie_alias = get_used_julie.email
      @users_associated_with_julie_alias = get_company_users(@data_holder.get_julie_aliases_company_association_cache[used_julie_alias])
      lookup_clients_with_julie_alias(@users_associated_with_julie_alias)
    end

    def check_possible_merging
      except = @messages_thread.id
      recipients_in_previous_threads = (@data_holder.get_last_3_weeks_threads_recipients(except) & @messages_thread.computed_recipients)
      to_merge = recipients_in_previous_threads.present?
      if to_merge
        @messages_thread.update(account_association_merging_possible: true, accounts_candidates: recipients_in_previous_threads)
      end

      to_merge
    end

    def get_company_users(company_name)
      JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get(company_name) || '[]')
    end

    def find_clients_in_recipients
      find_account_emails
    end

    def build_regexp(array_to_search)
      regexp = Regexp.new("(?:#{array_to_search.map{ |search_param| Regexp.escape(search_param) }.join('|')})")

      @logger.debug("-- Used regexp => #{regexp} --")

      regexp
    end

    def look_up_clients_in_emails_bodies(array_to_search)
      result = Set.new(get_thread_emails_bodies.scan(build_regexp(array_to_search)))

      @logger.debug("-- Looking for following persons => #{array_to_search.inspect} --")
      @logger.debug("-- In following text => #{get_thread_emails_bodies} --")
      @logger.debug("-- found => #{result.inspect} --")

      result
    end

    # Try to find any clients in the recipients
    # We search in the following fields, sorted by search order => from > to > cc
    def find_account_emails
      account_emails = get_accounts_emails(@recipients_emails[:from])

      if account_emails.blank?
        account_emails = get_accounts_emails(@recipients_emails[:to])

        if account_emails.blank?
          account_emails = get_accounts_emails(@recipients_emails[:cc])
        end
      end

      account_emails
    end

    def get_accounts_emails(array)
      array.map{|co| find_account_email(co)}.uniq.compact.map(&:downcase)
    end

    def find_account_email(email)
      Account.find_account_email(email, {accounts_cache: @data_holder.accounts_cache})
    end

    def extract_recipients_emails(recipients)
      addresses = ApplicationHelper.find_addresses(recipients.join(',')).addresses

      addresses.map{ |contact|
        {
            email: contact.address.downcase,
            name: contact.name
        }
      }.group_by{ |contact|
        contact[:email]
      }.map{ |_, contacts|
        contacts.max{|contact| "#{contact[:name]}".length}[:email]
      }
    end

  end
end