class MessagesThread < ActiveRecord::Base
  has_paper_trail only: [:tags]

  class SplitError < Exception
  end

  EVENT_SCHEDULED = "event_scheduled"
  SCHEDULING_EVENT = "scheduling_events"
  EVENTS_CREATED = "events_created"

  SYNCING_TAG = "syncing"
  AVAILABLE_TAGS = [SYNCING_TAG]

  has_many :messages
  has_many :operator_actions, as: :target
  has_many :operator_actions_groups
  has_many :mt_operator_actions, class_name: "OperatorAction", foreign_key: "messages_thread_id"
  has_many :event_title_reviews

  after_update :owner_changed?


  belongs_to :locked_by_operator, foreign_key: "locked_by_operator_id", class_name: "Operator"
  belongs_to :to_be_merged_operator, foreign_key: "to_be_merged_operator_id", class_name: "Operator"

  attr_writer :account
  attr_accessor :thread_blocked,
                :clients_with_linked_attendees_enabled,
                :clients,
                :has_inactive_owner,
                # Instance variable used to store whether we should track when this thread enter the inbox
                :track_inbox

  scope :in_inbox, -> { where("(in_inbox = ? OR should_follow_up = ?) AND handled_by_ai = ? AND handled_by_automation = ? AND was_merged = ? AND sent_to_admin = ?", true, true, false, false, false, false) }

  scope :in_inbox_only, -> { where("in_inbox = ? AND handled_by_ai = ? AND handled_by_automation = ? AND was_merged = ?", true, false, false, false) }

  scope :syncing, -> { where('? = ANY(tags)', 'syncing') }
  scope :not_syncing, -> { where('NOT (? = ANY(tags))', 'syncing') }
  scope :with_this_client, -> (account_email) { where('? = ANY(clients_in_recipients)', account_email) }

  include ApplicationHelper
  include TemplateGeneratorHelper

  BLOCKED_THREAD_NOTIFY_URL = ENV['JULIEDESK_APP_BASE_PATH'] + '/api/v1/calendar_access_lost/notify_email_blocked'

  def track_thread_in_inbox(from_inbox)
    if Rails.env.production?
      JuliedeskTrackerInterface.new.build_request(:track, {name: :thread_appeared_in_inbox, date:  Time.now.to_s, properties: {messages_thread_id: self.id, messages_count: self.messages_count, inbox_type: from_inbox}, distinct_id: "thread_#{self.id}_in_inbox"})
    end
  end

  def get_last_message
    messages.sort_by{|m| m.received_at}.last
  end

  def send_account_gone_unsubscribe_email
    last_message = get_last_message
    all_recipients = messages.map{|m| JSON.parse(m.reply_all_recipients).values}.flatten.map{|h| h['email']}.uniq
    client_all_emails = self.account.all_emails

    found_client_aliases = all_recipients & client_all_emails

    AutoReplyAccountNoticeWorker.enqueue(last_message.id, 'account_gone_unsubscribe.client', found_client_aliases.first)
    #last_message.send_account_notice_email('account_gone_unsubscribe.client', found_client_aliases.first)
  end

  def recompute_allowed_attendees_full
    messages = self.re_import
    julie_aliases_emails = JulieAlias.all.map(&:email)

    messages.each do|message|
      message.compute_allowed_attendees(julie_aliases_emails)
      message.save
    end

    self.compute_allowed_attendees
    self.save
  end

  def enqueue_account_not_configured_yet_automatic_email(message_id)
    AutoReplyAccountConfigurationPendingWorker.enqueue(message_id)
  end

  def archive
    EmailServer.archive_thread(messages_thread_id: self.server_thread_id)
    self.update({
                 should_follow_up: false,
                 in_inbox: false
               })

    if ENV['PUSHER_APP_ID']
      Pusher.trigger('private-global-chat', 'archive', {
          :message => 'archive',
          :message_thread_id => self.id
      })
    elsif ENV['RED_SOCK_URL']
      RedSock.trigger "private-global-chat", 'archive', {
          message: "archive",
          :message_thread_id => self.id
      }
    end
  end

  def self.basic_operator_check_thread_to_reject(messages_thread)
    !messages_thread.account ||
        messages_thread.sent_to_admin ||
        messages_thread.delegated_to_support ||
        messages_thread.account.only_admin_can_process ||
        messages_thread.account.only_support_can_process ||
        messages_thread.to_be_merged || messages_thread.thread_blocked ||
        messages_thread.owner_needs_configuration ||
        messages_thread.has_tag?(MessagesThread::SYNCING_TAG)
  end

  def self.super_operator_level_1_check_thread_to_reject(messages_thread)
    messages_thread.sent_to_admin ||
        (messages_thread.account && messages_thread.account.only_admin_can_process) ||
        messages_thread.thread_blocked ||
        messages_thread.owner_needs_configuration ||
        messages_thread.has_tag?(MessagesThread::SYNCING_TAG)
  end

  def self.filter_on_privileges(privilege, messages_threads)
    if privilege == Operator::PRIVILEGE_OPERATOR
      messages_threads.reject!{ |mt|
        self.basic_operator_check_thread_to_reject(mt)
      }
    elsif privilege == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1 || privilege == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2 || privilege == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_3
      messages_threads.reject!{ |mt|
        self.super_operator_level_1_check_thread_to_reject(mt)
      }
    end
  end

  def get_secondary_clients_emails
    self.clients_in_recipients - [self.account_email]
  end

  def deassociate_event
    self.get_event_data_julie.clear_event_data
  end

  def get_dates_to_verify
    result = {}

    every_propositions = get_all_suggested_date_times
    result[:last_proposition] = every_propositions.last

    now = DateTime.now
    result[:every_propositions] = every_propositions.flatten.uniq.map do |dt|
      date = DateTime.parse(dt['date'])
      if date > now
        {'timezone' => dt['timezone'], 'date' => date, 'date_with_timezone' => date.in_time_zone(dt['timezone'])}
      else
        nil
      end
    end.compact.sort_by do |dt|
      dt['date_with_timezone']
    end

    result
  end

  def get_all_messages_recipients
    recipients_emails = []
    messages.each{|m| recipients_emails.push(m.get_reply_all_recipients_emails)}
    recipients_emails.flatten.uniq
  end

  def server_thread params={}
    if @server_thread.nil? || params[:force_refresh]
      params = {
          server_thread_id: self.server_thread_id,
          show_split: params[:show_split]
      }

      params.merge!(messages_thread_id: self.id) if ENV['STAGING_APP']

      @server_thread = EmailServer.get_messages_thread(params)
    end
    @server_thread
  end

  def blocking_users(recipients, users_with_lost_access)
    recipients & users_with_lost_access
  end

  def self.users_with_threads_blocked
    Set.new(REDIS_FOR_ACCOUNTS_CACHE.smembers('user_threads_blocked'))
  end

  def check_if_blocked(users_with_lost_access, all_clients_emails)
    thread_computed_data_attendees = self.computed_data_only_attendees
    true_str = 'true'
    attendees_emails = self.computed_recipients

    if thread_computed_data_attendees && thread_computed_data_attendees[:attendees].size > 0
      attendees = thread_computed_data_attendees[:attendees]
      attendees_emails = attendees.select{|att| att['isClient'] == true_str && att['isPresent'] == true_str && all_clients_emails.include?(att['account_email'])}.map{|att| att['email']}
    else
      attendees_emails = attendees_emails.select{|att_email| all_clients_emails.include?(att_email)}
    end

    self.thread_blocked = blocking_users(Set.new(attendees_emails), users_with_lost_access).size > 0
  end

  def handle_recipients_lost_access(users_with_lost_access, accounts_cache)
    # recipients et users_with_lost_access sont des Set
    # on récupère les éléments en commun entre ces deux sets en utilisant l'opérateur '&'
    # Les éléments en commun sont les récipiendaires qui sont clients chez nous et dont on a perdu les accès à l'un de leurs calendriers
    recipients_clients = self.clients_in_recipients

    recipients_with_lost_access = blocking_users(Set.new(recipients_clients), users_with_lost_access)

    # Means the thread will be blocked because we have lost the calendar access of at least one the recipients
    if recipients_with_lost_access.size > 0
      last_message = self.messages.sort_by(&:updated_at).last
      body = {blocking_users_emails: recipients_with_lost_access.to_a, originated_from_thread_id: self.id}
      calendars_renew_links = ADMIN_API_INTERFACE.build_request(:get_blocking_users_calendars_renew_links, body)

      if calendars_renew_links.present?
        calendars_renew_links.each do |client_main_email, links|
          julie_sharings, links_to_renew = links.partition{|l| l[1] == 'julie_sharing'}

          if links_to_renew.size > 0
            AutoEmailWorker.enqueue(
                last_message.id,
                AutomaticsEmails::Rules::TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION,
                {
                    key: 'blocked_request_notification.with_renew_links.body',
                    client_name: accounts_cache[client_main_email]["usage_name"],
                    links_to_renew: links_to_renew.map{|l| I18n.translate('automatic_reply_emails.blocked_request_notification.formatted_links', {calendar_type: l[0], link_to_renew: l[1]})}.join(''),
                    count: links_to_renew.size
                },
                client_main_email
            )
          end

          if julie_sharings.size > 0
            AutoEmailWorker.enqueue(
                last_message.id,
                AutomaticsEmails::Rules::TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION,
                {
                    key: 'blocked_request_notification.with_calendar_sharing.body',
                    client_name: accounts_cache[client_main_email]["usage_name"],
                },
                client_main_email
            )
          end
        end
      end

    end
  end

  # DEPRECATED
  def old_handle_recipients_lost_access(recipients, users_with_lost_access, accounts_cache)
    # recipients et users_with_lost_access sont des Set
    # on récupère les éléments en commun entre ces deux sets en utilisant l'opérateur '&'
    # Les éléments en commun sont les récipiendaires qui sont clients chez nous et dont on a perdu les accès à l'un de leurs calendriers
    recipients_clients = recipients.select{|recipient_email| accounts_cache[recipient_email].present?}

    recipients_with_lost_access = blocking_users(Set.new(recipients_clients), users_with_lost_access)

    # Means the thread will be blocked because we have lost the calendar access of at least one the recipients
    if recipients_with_lost_access.size > 0
      body = {blocking_users_emails: recipients_with_lost_access, originated_from_thread_id: self.id}
      ADMIN_API_INTERFACE.build_request(:notify_blocked_threads, body)
      Rails.logger.info "Sent Blocked users for thread #{self.id}"
    end
  end

  def compute_linked_attendees(accounts_cache, forced_emails_to_check = nil)
    self.update(linked_attendees: LinkedAttendees::Manager.new(self, accounts_cache).fetch(forced_emails_to_check))
  end

  def account params={}
    if @account.present? || @account_fetched
      @account
    else
      @account_fetched = true
      @account = Account.create_from_email(account_email, params)
    end
  end

  def check_if_owner_inactive
    @has_inactive_owner ||= !self.account.subscribed
  end

  def owner_needs_configuration
    @has_unconfigured_owner ||= (self.account.present? && self.account.configuration_needed)
  end

  def async_archive
    ArchiveMessagesThreadWorker.enqueue(self.id)
  end

  def composed_accounts_candidates
    self.accounts_candidates_primary_list + self.accounts_candidates_secondary_list
  end

  def send_to_admin params={}
    attrs_to_update = {
        sent_to_admin: true,
        to_admin_message: "#{params[:message]}\n\n#{params[:operator]}"
    }
    attrs_to_update.merge!(has_been_sent_to_admin: true) if has_been_sent_to_admin == false
    self.update_attributes(attrs_to_update)

    if ENV['DONT_WARN_AND_FOUNDER_EMAILS'].nil?
      EmailServer.add_and_remove_labels({
                                            messages_thread_ids: [self.server_thread_id],
                                            labels_to_add: ["Founders"],
                                            labels_to_remove: []
                                        })
    end
  end

  def undelegate_to_admin params={}
    self.update_attributes({
                               sent_to_admin: false
                           })
    if ENV['DONT_WARN_AND_FOUNDER_EMAILS'].nil?
      EmailServer.add_and_remove_labels({
                                            messages_thread_ids: [self.server_thread_id],
                                            labels_to_add: [],
                                            labels_to_remove: ["Founders"]
                                        })
    end
  end

  def tag_as_multi_clients
    self.update_attributes(
        {
            is_multi_clients: true,
            delegated_to_support: true
        }
    )

    if ENV['DONT_WARN_AND_FOUNDER_EMAILS'].nil?
      EmailServer.add_and_remove_labels({
                                            messages_thread_ids: [self.server_thread_id],
                                            labels_to_add: ["Support"],
                                            labels_to_remove: []
                                        })
    end
  end

  def delegate_to_support params={}
    self.update_attributes({
                               delegated_to_support: true,
                               to_admin_message: "#{params[:message]}\n\n#{params[:operator]}"
                           })
    if ENV['DONT_WARN_AND_FOUNDER_EMAILS'].nil?
      EmailServer.add_and_remove_labels({
                                            messages_thread_ids: [self.server_thread_id],
                                            labels_to_add: ["Support"],
                                            labels_to_remove: []
                                        })
    end
  end

  def undelegate_to_support
    self.update_attributes({
                               delegated_to_support: false
                           })
    if ENV['DONT_WARN_AND_FOUNDER_EMAILS'].nil?
      EmailServer.add_and_remove_labels({
                                            messages_thread_ids: [self.server_thread_id],
                                            labels_to_add: [],
                                            labels_to_remove: ["Support"]
                                        })
    end
  end

  def julie_alias(params={})
    real_julie_aliases = self.julie_aliases(params)
    if real_julie_aliases.empty?
      JulieAlias.find_by_email(ENV['DEFAULT_JULIE_ALIAS_EMAIL'])
    else
      selected_real_julie_alias = nil

      # When there is an account linked to the thread, we will try to use the julie alias of him in priority if multiple julie account are available
      if account_email.present?
        if account = self.account
          thread_owner_julie_aliases = account.julie_aliases || []
          selected_real_julie_alias = (thread_owner_julie_aliases & real_julie_aliases.map(&:email)).first
          if selected_real_julie_alias.present?
            selected_real_julie_alias = JulieAlias.find_by_email(selected_real_julie_alias)
          end
        end
      end

      selected_real_julie_alias || real_julie_aliases.first
    end
  end

  def julie_aliases params={}
    MessagesThread.julie_aliases_from_server_thread(self.server_thread, {julie_aliases: params[:julie_aliases] || JulieAlias.all})
  end

  def contacts params = {}
    params[:server_messages_to_look] = server_thread['messages']
    params[:forbidden_emails] = []
    unless params[:with_client]
      params[:forbidden_emails] = account.try(:all_emails) || []
    end
    MessagesThread.contacts params
  end

  def create_event_title_review_if_needed
    if self.scheduling_status == MessagesThread::EVENT_SCHEDULED
      last_event_title_review = self.event_title_reviews.sort_by(&:created_at).last
      if last_event_title_review.nil? || last_event_title_review.title != self.computed_data[:summary]
        self.event_title_reviews.update_all(status: EventTitleReview::STATUS_REVIEWED)
        self.event_title_reviews.create(title: self.computed_data[:summary])
      end
    end
  end

  def compute_messages_request_at
    archives_at = self.mt_operator_actions.select{|oa| oa.nature == "archive"}.map(&:initiated_at)

    incoming_messages_received_at = self.messages.select{|m| !m.from_me}.map(&:received_at)
    messages_from_me = self.messages.select{|m| m.from_me && m.request_at.nil?}

    messages_from_me.each do |m|
      before_this_message_archives_at = archives_at.select{|dt| dt < m.received_at}.max
      request_at = incoming_messages_received_at.select{|dt|
        dt < m.received_at &&
            (
            before_this_message_archives_at.nil? ||
                dt > before_this_message_archives_at
            )
      }.min
      m.update_attribute :request_at, request_at
    end
  end

  def self.contacts params = {}
    to_addresses = params[:server_messages_to_look].map{|m| ApplicationHelper.find_addresses(m['to']).addresses}.flatten
    from_addresses = params[:server_messages_to_look].map{|m| ApplicationHelper.find_addresses(m['from']).addresses}.flatten
    cc_addresses = params[:server_messages_to_look].map{|m| ApplicationHelper.find_addresses(m['cc']).addresses}.flatten

    forbidden_emails = JulieAlias.all.map(&:email) + (params[:forbidden_emails] || [])

    (to_addresses + from_addresses + cc_addresses).select{ |contact|
      !forbidden_emails.map(&:downcase).include?(contact.address.try(:downcase))
    }.map{ |contact|
      {
          email: contact.address.downcase,
          name: contact.name
      }
    }.group_by{ |contact|
      contact[:email]
    }.map{ |_, contacts|
      contacts.max{|contact| "#{contact[:name]}".length}
    }
  end

  def find_or_compute_request_date
    unless request_date
      self.update_attribute :request_date, self.compute_request_date
    end
    request_date
  end

  def compute_request_date
    self.messages.select{|m| !m.archived}.map{|m| m.received_at}.min ||
        self.messages.map{|m| m.received_at}.max ||
        DateTime.parse("2500-01-01")
  end

  def computed_data_only_attendees
    message_classifications = messages.map{|m|
      m.message_classifications
    }.flatten.sort_by(&:updated_at).select(&:has_data?).compact
    last_message_classification = message_classifications.last

    {
        attendees: JSON.parse(last_message_classification.try(:attendees) || "[]"),
    }
  end

  def computed_data_light
    message_classifications = messages.map{|m|
      m.message_classifications
    }.flatten.sort_by(&:updated_at).select(&:has_data?).compact
    last_message_classification = message_classifications.last
    appointment_nature = last_message_classification.try(:appointment_nature)

    {
        appointment_nature: appointment_nature,
        attendees: JSON.parse(last_message_classification.try(:attendees) || "[]"),
        summary: last_message_classification.try(:summary),
        date_times: message_classifications.map{|mc| JSON.parse(mc.date_times || "[]")}.flatten.sort_by{|dt|
          dt['date'] || "ZZZ"
        },
        last_message_sent_at: messages.select(&:from_me).sort_by(&:received_at).last.try(:received_at),
    }
  end

  def last_message_classification_with_data
    message_classifications = messages.map{|m|
      m.message_classifications
    }.flatten.sort_by(&:updated_at).select(&:has_data?).compact

    message_classifications.last
  end

  def computed_data message_classifications=nil
    if @computed_data.blank?

      unless message_classifications
        message_classifications = messages.map{|m|
          m.message_classifications
        }.flatten.sort_by(&:updated_at).select(&:has_data?).compact
      end

      last_message_classification = message_classifications.last
      appointment_nature = last_message_classification.try(:appointment_nature)

      begin
        computed_calendar_login_username = self.calendar_login.try(:[], 'username')

        computed_calendar_login_type = self.calendar_login.try(:[], 'type')
      rescue
        computed_calendar_login_username = nil
        computed_calendar_login_type = nil
      end
      @computed_data = {
          locale: last_message_classification.try(:locale) || self.account.try(:locale),
          timezone: last_message_classification.try(:timezone) || self.account.try(:default_timezone_id),
          appointment_nature: appointment_nature,
          summary: last_message_classification.try(:summary),
          duration: last_message_classification.try(:duration) || 60,
          location_nature: last_message_classification.try(:location_nature),
          location: last_message_classification.try(:location),
          call_instructions: JSON.parse(last_message_classification.try(:call_instructions) || "[]"),
          attendees: JSON.parse(last_message_classification.try(:attendees) || "[]"),
          notes: last_message_classification.try(:notes),
          other_notes: last_message_classification.try(:other_notes),
          client_on_trip: last_message_classification.try(:client_on_trip),

          is_virtual_appointment: MessagesThread.virtual_appointment_natures.include?(appointment_nature),

          private: last_message_classification.try(:private),

          client_agreement: last_message_classification.try(:client_agreement),
          attendees_are_noticed: last_message_classification.try(:attendees_are_noticed),

          constraints: last_message_classification.try(:constraints),
          constraints_data: JSON.parse(last_message_classification.try(:constraints_data) || "[]"),

          number_to_call: last_message_classification.try(:number_to_call),
          title_preference: last_message_classification.try(:title_preference),

          date_times: message_classifications.map{|mc| JSON.parse(mc.date_times || "[]")}.flatten.sort_by{|dt|
            dt['date'] || "ZZZ"
          },
          last_message_sent_at: messages.select(&:from_me).sort_by(&:received_at).last.try(:received_at),
          calendar_login_username: computed_calendar_login_username,
          calendar_login_type: computed_calendar_login_type,
          location_coordinates: last_message_classification.try(:location_coordinates),
          using_meeting_room: last_message_classification.try(:using_meeting_room),
          meeting_room_details: last_message_classification.try(:meeting_room_details),
          booked_rooms_details: last_message_classification.try(:booked_rooms_details),
          using_restaurant_booking: last_message_classification.try(:using_restaurant_booking),
          restaurant_booking_details: last_message_classification.try(:restaurant_booking_details),
          virtual_resource_used: last_message_classification.try(:virtual_resource_used),
          thread_recipients: self.computed_recipients,
          linked_attendees: self.linked_attendees,
          do_not_ask_suggestions: self.do_not_ask_suggestions?,
          language_level: last_message_classification.try(:language_level) || self.account.try(:language_level) || :normal,
          trusted_attendees: self.trusted_attendees,
          asap_constraint: last_message_classification.try(:asap_constraint).present?,
          auto_follow_up_enabled: self.auto_follow_up_enabled?,
          # We add in front the julie aliases emails and the services emails (hello@juliedesk.com)
          allowed_attendees: self.allowed_attendees,
          date_suggestions_full_ai: message_classifications.map(&:julie_action).compact.select(&:done).map(&:date_suggestions_full_ai).include?(true)
      }
    end

    @computed_data
  end

  def compute_allowed_attendees
    self.allowed_attendees = AllowedAttendees::ThreadManager.new(self).compute_allowed_attendees
  end

  # Auto follow up is enabled if at least one client on the thread has it enabled or if a previous follow up reminder date was set
  def auto_follow_up_enabled?
    self.clients.any?(&:auto_follow_up_enabled) || self.follow_up_reminder_date.present?
  end

  def trusted_attendees
    circle_of_trusts = self.clients.inject({}){|h, c|h[c.full_name]= c.circle_of_trust; h}
    # {
    #     emails: circle_of_trusts.map{|ct| ct['trusted_emails']}.flatten,
    #     domains: circle_of_trusts.map{|ct| ct['trusted_domains']}.flatten
    # }
  end

  def self.virtual_appointment_natures
    %w(skype call webex confcall hangout visio)
  end

  def self.items_to_classify_count
    MessagesThread.where(in_inbox: true).count
  end

  def should_reprocess_linked_attendees(computed_recipients_changed)
    computed_recipients_changed && has_clients_with_linked_attendees_enabled
  end

  def has_clients_with_linked_attendees_enabled
    get_clients_with_linked_attendees_enabled.size > 0
  end

  def get_clients_with_linked_attendees_enabled
    @clients_with_linked_attendees_enabled ||= clients.select{|c| c.linked_attendees_enabled}
  end

  def attendees_has_changed(old_attendees_emails, new_attendees_emails)
    # old_emails is sent from frontend and is already constitued of only the present attendees
    old_attendees_emails != new_attendees_emails
  end

  def check_recompute_linked_attendees(old_attendees, new_attendees)
    old_attendees ||= {}
    if new_attendees.present?
      old_attendees_emails = (old_attendees.class == Array ? old_attendees : old_attendees.values).map{|a| a['email']}.compact.sort
      new_attendees_emails = (new_attendees.class == Array ? new_attendees : new_attendees.values).map{|a| a['isPresent'] == 'true' ? a['email'] : nil}.compact.sort

      if self.has_clients_with_linked_attendees_enabled && self.attendees_has_changed(old_attendees_emails, new_attendees_emails)
        self.compute_linked_attendees(Account.accounts_cache(mode: "light"), new_attendees_emails)
      end
    end
  end

  def secondary_clients
    unless @secondary_clients
      @secondary_clients = self.get_secondary_clients_emails.map{|client_email| Account.create_from_email(client_email)}.compact
    end

    @secondary_clients
  end

  def clients
    # We compact it because clients can become deactivated in the mean time, so they will not be in the cache anymore
    unless @clients
      recipients_clients = Set.new(self.clients_in_recipients)
      # In case accounts has been associated later to other client, so he is not in recipients
      recipients_clients.add(self.account_email)
      @clients = recipients_clients.to_a.map do |client_email|
        account = Account.create_from_email(client_email)
        if account && account.subscribed
          account
        end

      end.compact
    end

    @clients
  end

  def several_accounts_detected(params={})
    if self.clients_in_recipients.present?
      self.clients_in_recipients.size > 1
    else
      contacts = MessagesThread.contacts(server_messages_to_look: server_thread['messages'])
      other_emails = contacts.map{|contact| contact[:email]}
      account_emails = (other_emails.map{|co| Account.find_account_email(co, {accounts_cache: params[:accounts_cache]})}.uniq.compact.map(&:downcase) - JulieAlias.all.map(&:email))

      accounts = account_emails.map{|account_email|
        Account.create_from_email(account_email, {accounts_cache: params[:accounts_cache]})
      }
      company_names = accounts.map{|account|
        account.company_hash.try(:[], 'name')
      }
      if company_names.select{ |company_name|
        company_name.nil?
      }.length > 0
        company_names.length > 1
      else
        company_names.uniq.length > 1
      end
    end
  end

  def self.several_accounts_detected server_thread, params={}
    contacts = self.contacts(server_messages_to_look: server_thread['messages'])
    other_emails = contacts.map{|contact| contact[:email]}
    account_emails = (other_emails.map{|co| Account.find_account_email(co, {accounts_cache: params[:accounts_cache]})}.uniq.compact.map(&:downcase) - JulieAlias.all.map(&:email))

    accounts = account_emails.map{|account_email|
      Account.create_from_email(account_email, {accounts_cache: params[:accounts_cache]})
    }
    company_names = accounts.map{|account|
      account.company_hash.try(:[], 'name')
    }
    if company_names.select{ |company_name|
      company_name.nil?
    }.length > 0
      company_names.length > 1
    else
      company_names.uniq.length > 1
    end
  end

  def get_all_suggested_date_times
    sorted_jas = get_julie_actions_with_dates_suggestions.sort_by(&:created_at)

    if sorted_jas.present?
      sorted_jas.map{|ja|JSON.parse(ja.date_times || '[]')}
    else
      []
    end
  end

  def suggested_date_times
    messages.map{ |m|
      m.message_classifications.map(&:julie_action).compact.select{ |ja|
        (ja.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES ||
            ja.action_nature == JulieAction::JD_ACTION_POSTPONE_EVENT ||
            ja.action_nature == JulieAction::JD_ACTION_CHECK_AVAILABILITIES ||
            ja.action_nature == JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS)
      }.map{ |ja|
        JSON.parse(ja.date_times || "[]")
      }
    }.flatten.uniq
  end

  def get_julie_actions_with_dates_suggestions
    messages.map{ |m|
      m.message_classifications.map(&:julie_action).compact.select{ |ja|
        (ja.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES ||
            ja.action_nature == JulieAction::JD_ACTION_POSTPONE_EVENT ||
            ja.action_nature == JulieAction::JD_ACTION_CHECK_AVAILABILITIES ||
            ja.action_nature == JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS) && ja.date_times.present? && ja.date_times != '[]'
      }
    }.flatten.uniq
  end

  def last_suggested_date_times
    sorted_jas = get_julie_actions_with_dates_suggestions.sort_by(&:created_at)

    if sorted_jas.present?
      JSON.parse(sorted_jas.last.date_times || '[]')
    else
      []
    end
  end

  def all_timezones
    (messages.map{ |m|
      m.message_classifications.map(&:julie_action).compact.select{ |ja|
        ja.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES
      }.map{ |ja|
        JSON.parse(ja.date_times).map{|dt| dt['timezone']}
      }
    }.flatten + messages.map{ |m|
      m.message_classifications.select{ |mc|
        mc.classification == MessageClassification::ASK_AVAILABILITIES
      }.map{ |mc|
        JSON.parse(mc.date_times).map{|dt| dt['timezone']}.select{|tz| tz.present?}
      }
    }.flatten).compact.uniq
  end

  def messages_to_classify
    messages.select{|m| m.message_classifications.empty?}
  end

  def received_at
    messages.map(&:received_at).max
  end

  def re_import
    existing_messages = []
    all_messages = self.server_thread(force_refresh: true, show_split: true).try(:[], 'messages') || []
    messages_thread_messages = self.messages

    all_messages.select do |server_message|
      server_message['messages_thread_id'] == self.server_thread_id && !server_message['duplicate']
    end.each do |server_message|
      server_message['from'].try(:gsub!, '?', '')
      server_message['cc'].try(:gsub!, '?', '')
      server_message['to'].try(:gsub!, '?', '')


      message = messages_thread_messages.find{|m| m.server_message_id == server_message['id']}
      unless message
        message = messages_thread_messages.create server_message_id: server_message['id'],
                                       received_at: DateTime.parse(server_message['date']),
                                       reply_all_recipients: Message.generate_reply_all_recipients(server_message).to_json,
                                       from_me: server_message['from_me']
      end
      message.server_message = server_message
      existing_messages << message
    end

    (messages_thread_messages - existing_messages).each do |message|
      message.clean_delete
    end

    computed_request_date = self.compute_request_date
    if self.request_date != computed_request_date
      self.request_date = computed_request_date
      self.save
    end

    @splitted_server_messages = all_messages.select do |server_message|
      server_message['messages_thread_id'] != self.server_thread_id
    end

    self.messages = messages_thread_messages && existing_messages
  end

  def splitted_server_messages
    @splitted_server_messages || []
  end

  def split message_ids
    raise SplitError.new("Cannot split thread without message id") if message_ids.blank?

    server_message_ids = self.messages.where(id: message_ids).map(&:server_message_id)
    EmailServer.split_messages({ messages_thread_id: self.server_thread_id, message_ids: server_message_ids })
    ImportEmailsWorker.enqueue
  end

  def has_already_processed_action_once(action_type)
    has_already_processed_once = false
    occurences_count = 0

    messages.each do |m|

      occurences_count += m.message_classifications.where(classification: action_type).size

      if occurences_count > 1
        has_already_processed_once = true
        break
      end
    end

    has_already_processed_once
  end

  def sorted_message_classifications
    messages.map(&:message_classifications).flatten.sort_by(&:updated_at)
  end

  def scheduling_status
    sorted_mcs = sorted_message_classifications
    # We check if there has been an MessageClassification::ASK_CREATE_EVENT that was initiated and finished (julie_action.done), we also check if the events has not been deleted after that
    # with created_events_data.present?
    if sorted_mcs.select{|mc| mc.classification == MessageClassification::ASK_CREATE_EVENT && mc.julie_action.done}.length > 0 && created_events_data.present?
      EVENTS_CREATED
    elsif event_data[:event_id]
      EVENT_SCHEDULED
    elsif sorted_mcs.select{|mc| (mc.classification == MessageClassification::ASK_DATE_SUGGESTIONS || mc.classification == MessageClassification::ASK_AVAILABILITIES || mc.classification == MessageClassification::WAIT_FOR_CONTACT) && mc.julie_action.present? && mc.julie_action.done}.length > 0
      SCHEDULING_EVENT
    else
      nil
    end
  end

  def compute_contacts
    possible_attendees = []
    current_attendees = []

    already_registered_contacts = (self.computed_data[:attendees] || [])
    already_registered_contacts.each do |attendee|
      unless attendee['isPresent'] == 'false'
        attendee['isPresent'] = 'true'
      end
    end

    already_registered_contacts_with_emails, already_registered_contacts_without_emails = already_registered_contacts.partition{ |att| att['email'].present? }
    parsed_contacts = self.full_contacts
    contacts_from_same_company = self.account.contacts_from_same_company

    possible_attendees = [already_registered_contacts_with_emails, contacts_from_same_company, parsed_contacts].inject([], :concat).map(&:symbolize_keys)
    possible_attendees.each{ |att| att[:email] = att[:email].downcase }
    possible_attendees.uniq!{ |att| att[:email] }

    # Add the attendees without an email at the end, so they won't be removed by a uniq email operation (This would cause to remove every attendee without an email except the first)
    possible_attendees.concat(already_registered_contacts_without_emails)
  end

  def full_contacts
    accounts = Account.accounts_cache(mode: "light")

    full_details_contacts = contacts.each do |attendee|
      accounts.each do |email, account|
        if account["state"] == "active_state"
          all_emails = [account['email']] + account['email_aliases']

          if all_emails.include? attendee[:email]
            julie_alias = account['julie_aliases'] && account['julie_aliases'].first
            json_julie_alias = julie_alias ? {email: julie_alias['email'], displayName: "#{julie_alias['first_name']} #{julie_alias['last_name']}"}.to_json : nil
            attendee.merge!({
                            #email: email,
                            account_email: email,
                            name: account['full_name'],
                            isClient: 'true',
                            assisted: "#{json_julie_alias.present?}",
                            assistedBy: json_julie_alias
                          })
          end
        end
      end
    end

    full_details_contacts_clients, full_details_contacts_non_clients = full_details_contacts.partition{|c| c[:account_email].present?}

    full_details_contacts_clients.uniq!{|c| c[:account_email]}

    full_details_contacts_clients + full_details_contacts_non_clients
  end

  def possible_contacts_for_cache
    thread_contacts = []
    accounts = Account.accounts_cache(mode: "light")

    contacts.each do |attendee|
      accounts.each do |email, account|
        all_emails = [account['email']] + account['email_aliases']

        if all_emails.include? attendee[:email]
          julie_alias = account['julie_aliases'] && account['julie_aliases'].first
          json_julie_alias = julie_alias ? {email: julie_alias['email'], displayName: "#{julie_alias['first_name']} #{julie_alias['last_name']}"}.to_json : nil
          thread_contacts << {
              email: email,
              account_email: email,
              name: account['full_name'],
              isClient: 'true',
              assisted: "#{json_julie_alias.present?}",
              assistedBy: json_julie_alias
          }
        end
      end
    end

    (self.account.contacts_from_same_company + thread_contacts).uniq{|c| c[:email]}
  end

  def client_email
    if account
      contact_emails = contacts(with_client: true).map{|c| c[:email]}
      contact_emails.each do |email|
        if account.all_emails.map(&:downcase).include? "#{email}".downcase
          return email
        end
      end

      account_email
    else
      nil
    end
  end

  def calendar_login
    if account && account.calendar_logins.present?
      # TODO Why not use self.account_email instead of self.client_email producing a 3 secondes request
      account.find_calendar_login_with_rule_data({
                                                   email_alias: self.client_email
                                                 })
    else
      nil
    end
  end

  # <b>DEPRECATED:</b> All thread accounts associations have been moved to ThreadAccountAssociation::Manager.
  # Not used anymore
  def self.find_account_email server_thread, params={}
    #raise Exceptions::ThreadAccountAssociation::MigratedMethodError

    account_emails = self.find_account_emails(server_thread, params)
    if account_emails.length == 1
      account_emails[0]
    else
      nil
    end
  end

  # <b>DEPRECATED:</b> All thread accounts associations have been moved to ThreadAccountAssociation::Manager.
  def self.find_account_emails server_thread, params={}
    #raise Exceptions::ThreadAccountAssociation::MigratedMethodError

    first_email = server_thread['messages'].sort_by{|m| DateTime.parse(m['date'])}.first
    return [] if first_email.nil?
    email = ApplicationHelper.strip_email(first_email['from'])

    account_emails = [Account.find_account_email(email, {accounts_cache: params[:accounts_cache]})].compact

    # Account is not the sender
    if account_emails.empty?
      contacts = self.contacts(server_messages_to_look: [first_email])
      other_emails = contacts.map{|contact| contact[:email]}
      account_emails = (other_emails.map{|co| Account.find_account_email(co, {accounts_cache: params[:accounts_cache]})}.uniq.compact.map(&:downcase) - JulieAlias.all.map(&:email))
    end

    account_emails
  end

  # Used for debugging purposes
  def get_event_data_julie
    self.messages.map(&:message_classifications).flatten.map(&:julie_action).select(&:done).sort_by(&:updated_at).select{|ja|
      ja.event_id
    }.last
  end

  def event_data
    if @event_data.blank?
      julie_actions = self.messages.map(&:message_classifications).flatten.map(&:julie_action).compact.select(&:done).sort_by(&:updated_at)

      last_cancellation = julie_actions.select{|ja|
        ja.deleted_event
      }.last

      last_creation = julie_actions.select{|ja|
        ja.event_id
      }.last

      @event_data = if last_creation && (last_cancellation.nil? || julie_actions.index(last_creation) > julie_actions.index(last_cancellation))
                      {
                          event_id: last_creation.event_id,
                          event_url: last_creation.event_url,
                          calendar_id: last_creation.calendar_id,
                          appointment_nature: last_creation.message_classification.appointment_nature,
                          calendar_login_username: last_creation.calendar_login_username,
                          event_from_invitation: last_creation.event_from_invitation,
                          event_from_invitation_organizer: last_creation.event_from_invitation_organizer
                      }
                    else
                      {
                          event_id: nil,
                          calendar_id: nil,
                          event_url: nil,
                          appointment_nature: nil,
                          calendar_login_username: nil,
                          event_from_invitation: false,
                          event_from_invitation_organizer: nil
                      }
                    end
    end
    @event_data
  end

  def created_events_julie_action
    julie_action = self.messages.map(&:message_classifications).flatten.map(&:julie_action).select{|ja|
      ja.done &&
          ja.action_nature == JulieAction::JD_ACTION_CREATE_EVENT
    }.sort_by(&:updated_at).last
  end

  def created_events_data
    julie_action = self.messages.map(&:message_classifications).flatten.map(&:julie_action).select{|ja|
      ja.done &&
          ja.action_nature == JulieAction::JD_ACTION_CREATE_EVENT
    }.sort_by(&:updated_at).last

    if julie_action
      JSON.parse(julie_action.events || "[]")
    else
      []
    end
  end

  def available_classifications
    if self.server_thread['labels'].include? "WeeklyRecap"
      return {
          other: [
            MessageClassification::UNKNOWN,
            MessageClassification::FOLLOWUP_ON_WEEKLY_RECAP,
            MessageClassification::FORWARD_TO_SUPPORT
        ]
      }
    end
    if account_email
      s_status = scheduling_status
      if s_status == EVENTS_CREATED
        {
            manage_events: [
                MessageClassification::ASK_CREATE_EVENT
            ],
            other: [
                MessageClassification::FORWARD_TO_CLIENT,
                MessageClassification::UNKNOWN,
                MessageClassification::FORWARD_TO_SUPPORT
            ]
        }
      elsif s_status == SCHEDULING_EVENT
        {
            event_scheduling: [
                MessageClassification::ASK_DATE_SUGGESTIONS,
                MessageClassification::ASK_AVAILABILITIES,
                MessageClassification::WAIT_FOR_CONTACT,
                MessageClassification::FOLLOW_UP_CONTACTS,
                MessageClassification::FOLLOW_UP_CLIENT,
                MessageClassification::GIVE_INFO,
                MessageClassification::ASK_INFO,
                MessageClassification::INVITATION_ALREADY_SENT
            ],
            other: [
                MessageClassification::FORWARD_TO_CLIENT,
                MessageClassification::UNKNOWN,
                MessageClassification::FORWARD_TO_SUPPORT
            ]
        }
      elsif s_status == EVENT_SCHEDULED
        {
            manage_scheduled_event: [
                MessageClassification::UPDATE_EVENT,
                MessageClassification::ASK_INFO,
                MessageClassification::ASK_CANCEL_APPOINTMENT,
                MessageClassification::INVITATION_ALREADY_SENT
            ],
            event_rescheduling: [
                MessageClassification::ASK_DATE_SUGGESTIONS,
                MessageClassification::ASK_AVAILABILITIES,
                MessageClassification::WAIT_FOR_CONTACT
            ],
            other: [
                MessageClassification::FORWARD_TO_CLIENT,
                MessageClassification::UNKNOWN,
                MessageClassification::FORWARD_TO_SUPPORT
            ]
        }
      elsif s_status == nil
        {
            event_scheduling: [
                MessageClassification::ASK_DATE_SUGGESTIONS,
                MessageClassification::ASK_AVAILABILITIES,
                MessageClassification::WAIT_FOR_CONTACT,
                MessageClassification::FOLLOW_UP_CONTACTS,
                MessageClassification::FOLLOW_UP_CLIENT,
                MessageClassification::INVITATION_ALREADY_SENT
            ],
            other: [
                MessageClassification::ASK_CREATE_EVENT,
                MessageClassification::ASK_CANCEL_EVENTS,
                MessageClassification::ASK_POSTPONE_EVENTS,
                MessageClassification::FORWARD_TO_CLIENT,
                MessageClassification::UNKNOWN,
                MessageClassification::FORWARD_TO_SUPPORT
            ]
        }
      end
    else
      {
          other: [
              MessageClassification::FORWARD_TO_CLIENT,
              MessageClassification::UNKNOWN,
              MessageClassification::FORWARD_TO_SUPPORT
          ]
      }
    end

  end

  def last_message_classification
    @last_message_classification ||= self.messages.map(&:message_classifications).flatten.select{|mc| mc.julie_action.present? && mc.julie_action.done}.sort_by(&:updated_at).last
  end

  def last_email_status(params = {})
    last_message = (params[:messages] || self.messages).sort_by(&:received_at).last
    return nil if last_message.nil?

    if last_message.from_me
      lmc = self.last_message_classification
      if lmc.nil?
        "not_from_me"
      elsif lmc.classification == MessageClassification::UNKNOWN
        "from_me_free_reply"
      else
        "from_me"
      end
    else
      "not_from_me"
    end
  end

  def suggested_current_status
    if self.event_data[:event_id].present?
      MessageClassification::THREAD_STATUS_SCHEDULED
    else
      self.messages.map(&:message_classifications).flatten.select{|mc| mc.julie_action.try(:done)}.sort_by(&:updated_at).map(&:computed_thread_status).compact.last
    end
  end

  def current_status
    self.status || self.messages.map(&:message_classifications).flatten.select{|mc| mc.julie_action.try(:done)}.sort_by(&:updated_at).map(&:thread_status).compact.last
  end

  def self.julie_aliases_from_server_thread server_thread, params={}
    server_thread['messages'].map do |server_message|
      Message.julie_aliases_from_server_message(server_message, {julie_aliases: params[:julie_aliases]})
    end.flatten.uniq
  end

  def classification_category_for_classification classification
    available_classifications.select{|k, v|
      v.include? classification
    }.map{|k, v| k}.first.to_s
  end

  def locked_by_operator_name
    self.locked_by_operator.try(:name)
  end

  def self.get_locks_statuses_hash
    MessagesThread.where("locked_by_operator_id IS NOT NULL").map{|mt|
      {
        operator_name: mt.locked_by_operator_name,
        messages_thread_id: mt.id
      }
    }
  end

  def only_human_first_message
    first_message = self.messages.sort_by(&:received_at).first
    ja = first_message.message_classifications.map(&:julie_action).compact.first
    julie_message = self.messages.find{|m| m.server_message_id == ja.server_message_id}
    julie_message.server_message['read'] = false

    self.messages = [first_message, julie_message]

    self.computed_data(first_message.message_classifications.sort_by(&:updated_at).select(&:has_data?).compact.first(1))
  end


  def mock_conscience_first_message
    first_message = self.messages.sort_by(&:received_at).first
    auto_message_classification = first_message.auto_message_classification
    self.instance_variable_set(:@event_data, {
        event_id: nil,
        calendar_id: nil,
        event_url: nil,
        appointment_nature: nil,
        calendar_login_username: nil,
        event_from_invitation: false,
        event_from_invitation_organizer: nil
    })
    self.computed_data([auto_message_classification])

    def self.contacts params = {}
      first_message = self.messages.sort_by(&:received_at).first
      params[:server_messages_to_look] = server_thread['messages'].select{|sm| [first_message.server_message_id].include? sm['id']}
      params[:forbidden_emails] = []
      unless params[:with_client]
        params[:forbidden_emails] = account.try(:all_emails) || []
      end
      MessagesThread.contacts params
    end
  end

  def attendees
    attendees_hash = self.computed_data_only_attendees
    return nil unless attendees_hash.has_key?(:attendees)
    attendees_hash[:attendees].select { |attendee| attendee["isPresent"] == "true" }
  end

  # Will return every email associated with the current present attendees
  # So we take into account the fact that some attendees may not have any emails
  # In order to do that we don't compact the resulting array
  def attendees_emails
    return nil if self.attendees.nil?
    self.attendees.map { |attendee| attendee["account_email"] || attendee["email"] }
  end

  def client_attendees_emails
    return nil if self.attendees.nil?
    self.attendees.select { |attendee| attendee["isClient"] == "true" }.map { |attendee| attendee["account_email"] }.compact
  end

  def linked_attendees_emails
    linked_attendees.values.flatten.compact
  end

  def do_not_ask_suggestions_emails_to_check
    emails_to_check = self.client_attendees_emails
    if self.account.linked_attendees_enabled
      emails_to_check += self.linked_attendees_emails
    end

    emails_to_check
  end

  def do_not_ask_suggestions?
    main_client_preferences = self.account
    attendees_emails = self.attendees_emails
    return false if main_client_preferences.nil? || attendees_emails.empty?
    (self.attendees_emails - do_not_ask_suggestions_emails_to_check).empty?
  end

  # For dev purposes
  def clear_thread

    messages = self.messages
    messages_classifications = messages.map(&:message_classifications).flatten
    julie_actions = messages_classifications.map(&:julie_action).flatten

    julie_actions.each(&:destroy)
    messages_classifications.each(&:destroy)
  end

  # For dev purposes
  def duplicate_thread
    new_thread = self.dup
    new_thread.save

    self.messages.each do |message|
     new_message = message.dup
     new_message.messages_thread = new_thread
     new_message.save

      message.message_classifications.each do |mc|
        new_mc = mc.dup
        new_mc.message = new_message
        new_mc.save

        new_ja = mc.julie_action.dup
        new_ja.message_classification = new_mc
        new_ja.save
      end
    end

    new_thread.id
  end

  def client_emails
    emails = []
    emails += self.clients_in_recipients unless self.clients_in_recipients.nil?
    emails += self.client_attendees_emails unless self.client_attendees_emails.nil?
    emails.compact.uniq
  end

  def self.client_emails_from_inbox
    MessagesThread.includes(messages: :message_classifications).in_inbox.map(&:client_emails).flatten.uniq
  end

  def self.only_in_inbox_messages_server_ids
    # We do that in two queries to be able to use 'select' on the threads messages to avoid filling up the RAM for nothing
    # Using 'select' with an 'includes' is reported to have inconsistent behaviour
    mt_ids_in_inbox = MessagesThread.select(:id).in_inbox_only
    Message.select(:server_message_id).where(messages_thread_id: mt_ids_in_inbox).map(&:server_message_id)
  end

  def reset_auto_follow_up
    self.update(follow_up_reminder_date: nil)
  end


  def self.remove_syncing_tag(account_email)
    raise "account email should be present" if account_email.blank?
    messages_thread_ids = MessagesThread.in_inbox.syncing.with_this_client(account_email).select(&:calendars_synced?).map(&:id)
    MessagesThread.where(id: messages_thread_ids).update_all("tags = array_remove(tags, '#{SYNCING_TAG}')")
  end

  def self.add_syncing_tag(account_email)
    raise "account email should be present" if account_email.blank?
    MessagesThread.in_inbox.not_syncing.with_this_client(account_email).update_all("tags = array_append(tags, '#{SYNCING_TAG}')")
  end

  def remove_tag(tag)
    manage_tag(:delete, verify_tag(tag))
  end

  def add_tag(tag)
    return true if self.has_tag?(tag)
    self.tags = [] if self.tags.nil?
    manage_tag(:push, verify_tag(tag))
  end

  def has_tag?(tag)
    !!self.tags && self.tags.include?(tag)
  end

  def calendars_synced?
    return true if self.clients_in_recipients.blank?
    self.clients_in_recipients.all? { |email| Account.is_synced?(email) }
  end

  private

  def verify_tag(tag)
    raise "tag #{tag} is not allowed" unless AVAILABLE_TAGS.include?(tag)
    tag
  end

  def manage_tag(method, tag)
    raise "#{method} is not supported" unless [:push, :delete].include?(method)
    self.tags_will_change!
    self.tags.send(method, tag)
    self.save
  end

  def owner_changed?
    if self.account_email_changed?
      @account_fetched = false
    end
  end
end