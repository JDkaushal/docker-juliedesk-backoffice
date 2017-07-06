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
                :recipients_emails_for_last_message,
                :used_julie,
                :clients_found_in_bodies,
                :users_associated_with_julie_alias,
                :currently_using_julie_alias

    attr_accessor :can_suggest_merging

    BEHAVIOR_TREE = [
        {
            conditions: [
                { method: :thread_has_unconfigured_owner? },
                { method: :can_send_automatic_message? }
            ],
            action: :thread_owner_is_not_configured_actions
        },
        {
            conditions: [
                { method: :can_suggest_merging? },
                { method: :accounts_lists_are_empty? }
            ],
            action: :suggest_merging
        },
        {
            conditions: [
                { method: :thread_has_no_owner? },
                { method: :cannot_suggest_merging? },
                { method: :can_send_automatic_message? },
                { method: :accounts_lists_are_empty? }
            ],
            action: :send_automatic_email_then_archive
        }
    ]


    def initialize(params)
      @data_holder = params[:data_holder]
      @messages_thread = params[:messages_thread]
      @server_thread = params[:server_thread]
      @recipients_emails = {}
      @recipients_emails_for_last_message = {}
      @merging_data = nil

      @logger = Rails.logger

      @pick_new_thread_owner = @messages_thread.account_email.blank?
    end

    def compute_association
      clear_context
      compute_recipients_emails
      compute_accounts_candidates(@recipients_emails.try(:values).try(:flatten))

      process_association
    end

    def compute_association_v2
      compute_accounts_candidates_v2

      process_association_v2
    end

    def compute_accounts_candidates_v2(recipients = nil)
      clear_context
      compute_recipients_emails
      recipients ||= @recipients_emails.try(:values).try(:flatten)
      clients_in_recipients = get_accounts_emails(recipients)

      # We always put the messages thread main account in first position
      if clients_in_recipients.include?(@messages_thread.account_email)
        clients_in_recipients.reject!{|email| email == @messages_thread.account_email}
        clients_in_recipients.unshift(@messages_thread.account_email)
      end

      if clients_in_recipients.present?
        @messages_thread.clients_in_recipients = clients_in_recipients
      end

      compute_recipients_emails_for_last_message
      build_lists
    end

    def compute_accounts_candidates(recipients)
      accounts_candidates_in_bodies = []

      clients_in_recipients = get_accounts_emails(recipients)

      # We always put the messages thread main account in first position
      if clients_in_recipients.include?(@messages_thread.account_email)
        clients_in_recipients.reject!{|email| email == @messages_thread.account_email}
        clients_in_recipients.unshift(@messages_thread.account_email)
      end

      if using_julie_alias
        @logger.debug("-- Entrering flow => using_julie_alias --")
        accounts_candidates_in_bodies = find_clients_with_julie_alias
      else
        @logger.debug("-- Entrering flow => using main julie --")
        accounts_candidates_in_bodies = find_clients_with_main_julie[:association_candidates]
      end

      accounts_candidates = accounts_candidates_in_bodies + clients_in_recipients
      accounts_candidates += compute_candidates_on_trusted_attendees(accounts_candidates.to_a)

      if accounts_candidates.present?
        @messages_thread.accounts_candidates = accounts_candidates.to_a.uniq
      end

      if clients_in_recipients.present?
        @messages_thread.clients_in_recipients = clients_in_recipients
      end

      if @messages_thread.changed?
        @messages_thread.save
      end
    end

    def enter_owner_inactive_flow
      MessagesThreadFlows::ThreadOwnerIsInactive.new(self).trigger
    end
    
    private

    def accounts_lists_are_empty?
      @messages_thread.accounts_candidates_primary_list.blank? && @messages_thread.accounts_candidates_secondary_list.blank?
    end

    def thread_has_no_owner?
      @messages_thread.account_email.blank?
    end

    def send_automatic_email_then_archive
      send_account_request_email
      @messages_thread.archive
    end

    def can_send_automatic_message?
      !@messages_thread.account_request_auto_email_sent && !has_one_splitted_message
    end

    def cannot_suggest_merging?
      !can_suggest_merging?
    end

    def can_suggest_merging?
      if thread_has_no_owner?
        @can_suggest_merging ||= check_possible_merging_v2
      else
        false
      end
    end

    def suggest_merging
      if @merging_data.present?
        @messages_thread.update(@merging_data)
      end
    end

    def thread_has_unconfigured_owner?
      @messages_thread.account.present? && !@messages_thread.account.configured
    end

    def thread_owner_is_not_configured_actions
      first_message = get_first_thread_message

      if first_message
        message = Message.find_by(server_message_id: first_message['id'])
        @messages_thread.enqueue_account_not_configured_yet_automatic_email(message.id)
      end
    end

    def clear_context
      # We clear the context,
      # For example, reset the flag indicating that we could merge the thread, il will be set again if needed (if not, even when a potential account is found we would suggest the operator to merge the thread)
      @messages_thread.update(account_association_merging_possible: false)
    end

    def has_one_splitted_message
      get_server_messages.any?{|m| m['was_split']}
    end

    def get_server_messages
      @server_messages ||= @server_thread['messages']
    end

    def get_thread_emails_bodies
      @thread_messages_bodies ||= get_server_messages.map{|m| m['text']}.join.downcase
    end

    def compute_candidates_on_trusted_attendees(already_found_accounts_candidates)
      clients_in_emails_bodies = lookup_clients_on_attributes(@data_holder.accounts_cache.values, [:first_name, :last_name]) - already_found_accounts_candidates

      from_emails = get_recipients_from_all_messages[:from]
      accounts_candidates = []

      if clients_in_emails_bodies.present?
        clients_in_emails_bodies.map{|client_email| Account.create_from_email(client_email)}.each do |account|
          if account.present?
            from_emails.each do |from_email|
              if account.is_in_circle_of_trust?(from_email)
                accounts_candidates.push(account.email)
              end
            end
          end
        end
      end

      accounts_candidates
    end

    def get_first_thread_message
      if @first_thread_message.blank?
        @first_thread_message = get_server_messages.sort_by{|m| DateTime.parse(m['date'])}.first
      end
      @first_thread_message
    end


    def get_last_thread_message
      if @last_thread_message.blank?
        @last_thread_message = get_server_messages.sort_by{|m| DateTime.parse(m['date'])}.last
      end
      @last_thread_message
    end

    def get_recipients_from_last_message
      @recipients_from_last_message ||= {
          to: sanitize_recipients_array([get_last_thread_message['to']]),
          from: sanitize_recipients_array([get_last_thread_message['from']]),
          cc: sanitize_recipients_array([get_last_thread_message['cc']])
      }
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

    def compute_recipients_emails_for_last_message
      @recipients_emails_for_last_message[:from] = extract_recipients_emails(get_recipients_from_last_message[:from]) - @data_holder.julie_alias_emails
      @recipients_emails_for_last_message[:to] = extract_recipients_emails(get_recipients_from_last_message[:to]) - @data_holder.julie_alias_emails
      @recipients_emails_for_last_message[:cc] = extract_recipients_emails(get_recipients_from_last_message[:cc]) - @data_holder.julie_alias_emails
    end

    def compute_recipients_emails
      @recipients_emails[:from] = extract_recipients_emails(get_recipients_from_all_messages[:from]) - @data_holder.julie_alias_emails
      @recipients_emails[:to] = extract_recipients_emails(get_recipients_from_all_messages[:to]) - @data_holder.julie_alias_emails
      @recipients_emails[:cc] = extract_recipients_emails(get_recipients_from_all_messages[:cc]) - @data_holder.julie_alias_emails

      @logger.debug("-- Recipients found => #{@recipients_emails.inspect} --")
    end

    def get_clients_in_attendees
      attendees = @messages_thread.computed_data_only_attendees
      clients_attendees = []
      if attendees.present?
        clients_attendees = attendees.select{|att| att['isClient'] && att['isPresent']}
      end

      clients_attendees
    end

    def build_primary_list

      clients_in_last_message_from =  @data_holder.get_clients_accounts(get_accounts_emails(@recipients_emails_for_last_message[:from]))
      clients_in_last_message_to =    @data_holder.get_clients_accounts(get_accounts_emails(@recipients_emails_for_last_message[:to]))
      clients_in_last_message_cc =    @data_holder.get_clients_accounts(get_accounts_emails(@recipients_emails_for_last_message[:cc]))
      clients_in_attendees =          @data_holder.get_clients_accounts(get_clients_in_attendees.map{|att| att['email']})
      clients_in_recipients_from =    @data_holder.get_clients_accounts(get_accounts_emails(@recipients_emails[:from]))
      clients_in_recipients_to =      @data_holder.get_clients_accounts(get_accounts_emails(@recipients_emails[:to]))
      clients_in_recipients_cc =      @data_holder.get_clients_accounts(get_accounts_emails(@recipients_emails[:cc]))

      client_before_generation_present = @messages_thread.account.present?
      client_before_generation_company = @messages_thread.account.try(:company)

      same_company_as_cblg_subscribed_configured_condition = lambda do |client|
        client_before_generation_present &&
            client_before_generation_company.present? &&
            client.subscribed == true &&
            client.configured == true &&
            client.company == client_before_generation_company
      end

      subscribed_configured_condition = lambda do |client|
        client.subscribed == true &&
          client.configured == true
      end

      subscribed_not_configured_condition = lambda do |client|
        client.subscribed == true &&
            client.configured == false
      end

      list = [
          {
              clients_origin: clients_in_last_message_from,
              condition: same_company_as_cblg_subscribed_configured_condition
          },
          {
              clients_origin: clients_in_last_message_to,
              condition: same_company_as_cblg_subscribed_configured_condition
          },
          {
              clients_origin: clients_in_last_message_cc,
              condition: same_company_as_cblg_subscribed_configured_condition
          },
          {
              clients_origin: clients_in_attendees,
              condition: same_company_as_cblg_subscribed_configured_condition
          },
          {
              clients_origin: clients_in_recipients_from,
              condition: same_company_as_cblg_subscribed_configured_condition
          },
          {
              clients_origin: clients_in_recipients_to,
              condition: same_company_as_cblg_subscribed_configured_condition
          },
          {
              clients_origin: clients_in_recipients_cc,
              condition: same_company_as_cblg_subscribed_configured_condition
          },
          {
              clients_origin: clients_in_last_message_from,
              condition: subscribed_configured_condition
          },
          {
              clients_origin: clients_in_last_message_to,
              condition: subscribed_configured_condition
          },
          {
              clients_origin: clients_in_last_message_cc,
              condition: subscribed_configured_condition
          },
          {
              clients_origin: clients_in_attendees,
              condition: subscribed_configured_condition
          },
          {
              clients_origin: clients_in_recipients_from,
              condition: subscribed_configured_condition
          },
          {
              clients_origin: clients_in_recipients_to,
              condition: subscribed_configured_condition
          },
          {
              clients_origin: clients_in_recipients_cc,
              condition: subscribed_configured_condition
          },
          {
              clients_origin: clients_in_last_message_from,
              condition: subscribed_not_configured_condition
          },
          {
              clients_origin: clients_in_last_message_to,
              condition: subscribed_not_configured_condition
          },
          {
              clients_origin: clients_in_last_message_cc,
              condition: subscribed_not_configured_condition
          },
          {
              clients_origin: clients_in_attendees,
              condition: subscribed_not_configured_condition
          },
          {
              clients_origin: clients_in_recipients_from,
              condition: subscribed_not_configured_condition
          },
          {
              clients_origin: clients_in_recipients_to,
              condition: subscribed_not_configured_condition
          },
          {
              clients_origin: clients_in_recipients_cc,
              condition: subscribed_not_configured_condition
          }
      ]

      computed_list = list.map do |list_element|
        list_element[:clients_origin].select do |client|
          list_element[:condition].call(client)
        end
      end

      return Set.new(computed_list.flatten.map(&:email)).to_a
    end

    def build_secondary_list
      secondary_list = []

      @logger.debug '!' * 50
      @logger.debug 'Secondary List'

      clients_related_to_julie_alias = []
      clients_from_ics = []
      clients_in_bodies_with_emails = []

      if using_julie_alias
        @logger.debug 'Using Julie Alias'
        clients_related_to_julie_alias = find_clients_with_julie_alias
      end

      @logger.debug '*' * 50
      @logger.debug 'Clients related to julie alias'
      @logger.debug clients_related_to_julie_alias.inspect
      @logger.debug '*' * 50

      clients_from_ics = get_clients_from_ics_in_messages.map(&:email)

      @logger.debug '*' * 50
      @logger.debug 'Clients from ICS'
      @logger.debug clients_from_ics.inspect
      @logger.debug '*' * 50

      clients_in_bodies_with_emails = get_clients_in_emails_bodies.to_a

      @logger.debug '*' * 50
      @logger.debug 'Clients in bodies with emails'
      @logger.debug clients_in_bodies_with_emails.inspect
      @logger.debug '*' * 50
      secondary_list = clients_related_to_julie_alias + clients_from_ics + clients_in_bodies_with_emails

      if secondary_list.present?
        # To have the main emails in case we had found an alias
        secondary_list = get_accounts_emails(secondary_list)
      end

      Set.new(secondary_list).to_a.reject{|possible_account_email| possible_account_email == "?"}
    end

    def get_clients_from_ics_in_messages
      clients_from_ics = @messages_thread.messages.inject([]){|array, m| array += m.get_ics_attendees_if_any}
      @data_holder.get_clients_accounts(clients_from_ics)
    end

    def build_lists
      @messages_thread.accounts_candidates_primary_list = build_primary_list
      @messages_thread.accounts_candidates_secondary_list = build_secondary_list
    end

    # New association flow => https://docs.google.com/document/d/11x_Fs4dwR3BfV6zu2ELYKD6rZQyMHroyjq4wo-Z7aRI/edit#
    def process_association_v2
      if @messages_thread.account.blank?
        if @messages_thread.accounts_candidates_primary_list.present?
          associate_thread_to_next_candidate
        end

        apply_behaviors
      elsif @messages_thread.check_if_owner_inactive
        enter_owner_inactive_flow
      end
    end

    def associate_thread_to_next_candidate
      next_candidate = @data_holder.get_clients_accounts([@messages_thread.accounts_candidates_primary_list.first]).first
      @messages_thread.update(account_email: next_candidate.email, account_name: next_candidate.usage_name)
    end

    def apply_behaviors
      BEHAVIOR_TREE.each do |behavior|
        conditions_matched = true
        conditions = behavior[:conditions]
        conditions.each do |condition|
          condition_method, condition_params = condition[:method], condition[:params]
          conditions_matched = false unless send(condition_method, *condition_params)
        end

        action_method = behavior[:action]
        send(action_method) if conditions_matched
      end
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
        end
      end

      # If we could not find a proper account to associate to the thread
      if !result[:associated] && @messages_thread.accounts_candidates.blank?
        @logger.debug("-- Entrering flow => Thread still not associated --")

        @logger.debug("-- Trying to find merging candidate... --")

        # If no candidates found by any means in the current thread, we will check if any of the recipients in the thread is present in a thread from the last 3 weeks
        try_to_merge = check_possible_merging
        @logger.debug("-- will try to merge => #{try_to_merge} --")
        @logger.debug("-- automatic email already sent => #{@messages_thread.account_request_auto_email_sent} --")

        if !try_to_merge && !@messages_thread.account_request_auto_email_sent && !has_one_splitted_message
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
      @currently_using_julie_alias ||= used_julie && used_julie.email != ENV['COMMON_JULIE_ALIAS_EMAIL']
    end

    def find_clients_with_main_julie
      @found_clients_in_bodies ||= get_clients_in_emails_bodies

      {associated: false, association_candidates: @found_clients_in_bodies}
    end

    def get_clients_in_emails_bodies
      look_up_clients_in_emails_bodies(@data_holder.get_clients_emails)
    end

    def lookup_clients_on_attributes(clients_hash, attributes_to_search)
      clients_founds = Set.new

      attributes_to_search.each do |attribute_to_search|
        attribute_to_search_str = attribute_to_search.to_s
        found_attribute_values = look_up_clients_in_emails_bodies(clients_hash.map{ |u| u[attribute_to_search_str].try(:downcase) }.compact)
        clients_founds.merge(clients_hash.select{ |u| found_attribute_values.include?(u[attribute_to_search_str].try(:downcase)) })
      end

      clients_founds.to_a.map{ |client| client['email']}
    end

    def lookup_clients_with_julie_alias(users_associated_with_julie_alias)
      found_first_names = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['firstName'].try(:downcase)}.reject(&:blank?))
      found_last_names = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['lastName'].try(:downcase)}.reject(&:blank?))
      found_emails = look_up_clients_in_emails_bodies(users_associated_with_julie_alias.map{|u| u['email'].try(:downcase)}.reject(&:blank?))

      @clients_found_in_bodies = Set.new
      @clients_found_in_bodies.merge(users_associated_with_julie_alias.select{ |u| found_first_names.include?(u['firstName'].try(:downcase)) })
      @clients_found_in_bodies.merge(users_associated_with_julie_alias.select{ |u| found_last_names.include?(u['lastName'].try(:downcase)) })
      @clients_found_in_bodies.merge(users_associated_with_julie_alias.select{ |u| found_emails.include?(u['email'].try(:downcase)) })

      @clients_found_in_bodies = @clients_found_in_bodies.map{ |u| u['email']}
    end

    def find_clients_with_julie_alias
      used_julie_alias = get_used_julie.email
      @users_associated_with_julie_alias = get_company_users(@data_holder.get_julie_aliases_company_association_cache[used_julie_alias])
      lookup_clients_with_julie_alias(@users_associated_with_julie_alias)
    end

    def check_possible_merging_v2
      except = @messages_thread.id

      recipients_in_previous_threads = (@data_holder.get_last_3_weeks_threads_recipients(except) & @messages_thread.computed_recipients)
      to_merge = recipients_in_previous_threads.present?

      if to_merge
        @merging_data = {account_association_merging_possible: true, merging_account_candidates: recipients_in_previous_threads}
        # Done in 'suggest_merging' action
        #@messages_thread.update(account_association_merging_possible: true, merging_account_candidates: recipients_in_previous_threads)
      end

      to_merge
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
      regexp = Regexp.new("(?:#{array_to_search.map{ |search_param| "\\b#{Regexp.escape(search_param)}\\b" }.join('|')})")

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
      recipients_str = recipients.join(',')
      addresses = ApplicationHelper.find_addresses(recipients_str).addresses
      addresses.group_by { |contact| contact.address }.map{ |_, contacts|
        contacts.max{|contact| "#{contact.name}".length}.try(:address)
      }
    end

  end
end