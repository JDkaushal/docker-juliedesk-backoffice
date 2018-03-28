class Account

  attr_accessor :email,
                :appointments,
                :company_hash,
                :addresses,
                :usage_name,
                :full_name,
                :email_aliases,
                :raw_preferences,
                :current_notes,
                :default_timezone_id,
                :locale,
                :only_admin_can_process,
                :only_support_can_process,
                :block_until_preferences_change,
                :mobile_number,
                :landline_number,
                :confcall_instructions,
                :video_conference_instructions,
                :skype,
                :means_of_transport,
                :awaiting_current_notes,
                :contacts_from_same_company,
                :created_at,
                :current_life_duration_in_days,
                :complaints_count,
                :calendar_logins,
                :office_365_refresh_token_expired,
                :is_pro,
                :virtual_appointments_support_config,
                :virtual_appointments_company_support_config,
                :threads_count_today,
                :title_preferences,
                :travel_time_transport_mode,
                :language_level,
                :delay_between_appointments,
                :default_commuting_time,
                :have_priority,
                :auto_follow_up_enabled,
                :restaurant_booking_enabled,
                :linked_attendees_enabled,
                :julie_aliases,
                :using_calendar_server,
                :main_address,
                :calendar_access_lost,
                :ignore_non_all_day_free_events,
                :circle_of_trust,
                :lunch_time_preference,
                :gender,
                :auto_date_suggestions,
                :configured,
                :subscribed,
                :configuration_needed,
                :state,
                :user_id,
                :skype_for_business_meeting_generation_active,
                :preferred_meeting_rooms,
                :sfb_instructions,
                :last_sync_date


  RULE_VALIDATED = "rule_validated"
  RULE_UNVALIDATED = "rule_unvalidated"
  RULE_DEFAULT = "rule_default"

  LANGUAGE_LEVEL_NORMAL = "normal"
  LANGUAGE_LEVEL_FORMAL = "soutenu"

  WORKING_DAY_START = { hour: 8, min: 30, second: 0 }
  WORKING_DAY_END   = { hour: 18, min: 30, second: 0 }

  def self.create_from_email email, params={}
    cache = params[:accounts_cache]# || self.accounts_cache
    users_access_lost_cache = params[:users_access_lost_cache] || self.users_with_lost_access
    return nil unless email.present?
    data = get_account_details(email, {accounts_cache: cache})
    return nil unless data.present?
    account = self.new
    account.email = data['email']
    account.appointments = data['appointments'] || []
    account.addresses = data['addresses'] || []
    account.virtual_appointments_support_config = data['virtual_appointments_support_config']
    account.virtual_appointments_company_support_config = data['virtual_appointments_company_support_config']
    account.usage_name = data['usage_name']
    account.full_name = data['full_name']
    account.email_aliases = data['email_aliases']
    account.company_hash = data['company_hash']
    account.raw_preferences = data['raw_preferences']
    account.current_notes = data['current_notes']
    account.awaiting_current_notes = data['awaiting_current_notes']
    account.default_timezone_id = data['default_timezone_id']
    account.locale = data['locale']
    account.mobile_number = data['mobile_number']
    account.landline_number = data['landline_number']
    account.confcall_instructions = data['confcall_instructions']
    account.video_conference_instructions = data['video_conference_instructions']
    account.sfb_instructions = data['sfb_instructions']
    account.skype = data['skype']
    account.means_of_transport = data['means_of_transport']
    account.only_admin_can_process = data['only_admin_can_process']
    account.only_support_can_process = data['only_support_can_process']
    account.block_until_preferences_change = data['block_until_preferences_change']
    account.office_365_refresh_token_expired = data['office_365_refresh_token_expired']
    account.calendar_logins = data['calendar_logins']
    account.is_pro = data['is_pro']
    account.title_preferences = data['title_preferences']
    account.travel_time_transport_mode = data['travel_time_transport_mode']
    account.language_level = data['language_level']
    account.delay_between_appointments = data['delay_between_appointments']
    account.default_commuting_time = data['default_commuting_time']
    account.have_priority = data['have_priority']
    account.auto_follow_up_enabled = data['auto_follow_up_enabled']
    account.restaurant_booking_enabled = data['restaurant_booking_enabled']
    account.linked_attendees_enabled = data['linked_attendees_enabled']
    account.julie_aliases = data['julie_aliases']
    account.using_calendar_server = data['using_calendar_server']
    account.last_sync_date = data['last_sync_date'].present? ? DateTime.parse(data['last_sync_date']) : nil
    account.ignore_non_all_day_free_events = data['ignore_non_all_day_free_events']
    account.circle_of_trust = data['circle_of_trust']
    account.lunch_time_preference = data['lunch_time_preference']
    account.gender = data['gender']
    account.auto_date_suggestions = data['auto_date_suggestions']
    account.user_id = data['id']
    account.preferred_meeting_rooms = data['preferred_meeting_rooms'] || []

    account.configured = data['configured']
    account.subscribed = data['subscribed']
    account.state = data['state']

    account.skype_for_business_meeting_generation_active = data['skype_for_business_meeting_generation_active']

    account.configuration_needed = !account.configured

    account.calendar_access_lost = users_access_lost_cache.present? ? users_access_lost_cache.include?(account.email) : false

    begin
      account.created_at = DateTime.parse(data['created_at'])
    rescue
      account.created_at = DateTime.parse("1989-05-03")
    end

    account.current_life_duration_in_days = (Time.zone.now - account.created_at).to_i / 1.days

    account.complaints_count = data['complaints_count']

    # We skip generating the contacts from the same company on the home page, since it will be only used on the message
    # thread page and recalculated at this moment

    if params[:skip_contacts_from_company]
      account.contacts_from_same_company = []
    else
      account.build_contacts_from_same_company(accounts_cache: cache)
    end

    #account.contacts_from_same_company = []

    if params[:messages_threads_from_today].present?
      account.compute_threads_count_today(params[:messages_threads_from_today])
    end


    if account.addresses.present?
      account.main_address = account.addresses.find{|add| add['is_main_address']}
    end

    account
  end

  def self.find_active_and_configured_account_email email, params={}
    if params[:accounts_cache]
      accounts = params[:accounts_cache].values
    else
      accounts = Account.get_active_account_emails detailed: true
    end

    accounts.each do |account|
      if (account['subscribed'] && account['configured'] && (([account['email']] + account['email_aliases']).map(&:downcase).include? "#{email}".downcase))
        return account['email']
      end
    end

    nil
  end

  def self.find_active_account_email email, params={}
    if params[:accounts_cache]
      accounts = params[:accounts_cache].values
    else
      accounts = Account.get_active_account_emails detailed: true
    end

    accounts.each do |account|
      if (account['subscribed'] && (([account['email']] + account['email_aliases']).map(&:downcase).include? "#{email}".downcase))
        return account['email']
      end
    end

    nil
  end

  def self.find_account_email email, params={}
    if params[:accounts_cache]
      accounts = params[:accounts_cache].values
    else
      accounts = Account.get_active_account_emails detailed: true
    end

    accounts.each do |account|
      if ([account['email']] + account['email_aliases']).map(&:downcase).include? "#{email}".downcase
        return account['email']
      end
    end

    nil
  end


  def has_current_notes?
    self.current_notes.present?
  end

  def self.create_for_autocomplete(email, params)
    cache = params[:accounts_cache]
    found_accounts = []
    account_email = self.find_account_email(email, accounts_cache: cache)

    if account_email.present?
      data = get_account_details(account_email, {accounts_cache: cache})

      if data.present?
        company_name = data['company_hash'].try(:[], 'name')
        main_account = {email: data['email'], name: data['full_name'], company: company_name}

        found_accounts.push(main_account)
        data['email_aliases'].each do |email_alias|
          alias_account = main_account.dup
          alias_account[:email_alias] = email_alias
          found_accounts.push(alias_account)
        end
      end
    end

    found_accounts
  end

  def company
    self.company_hash.try(:[], 'name')
  end

  def any_phone_number
    self.landline_number || self.mobile_number
  end

  # Maybe not the correct way
  def compute_threads_count_today(messages_threads_from_today)
    today_threads_count = messages_threads_from_today[self.email]

    self.threads_count_today = today_threads_count
  end

  def number_to_call
    appointments.select{|appointment|
      appointment['type'] == "call"
    }.first.try(:[], 'number_to_call')
  end

  def julie_can_process_now
    return true unless self.company_hash
    timezoned_now = DateTime.now.in_time_zone(self.company_hash['timezone'])
    timezoned_day = timezoned_now.strftime("%a").downcase
    day_working_hours = self.company_hash['working_hours'].try(:[], timezoned_day)
    timezoned_hour_and_minutes = timezoned_now.strftime("%H%m").to_i

    (day_working_hours || {}).any? do |k, working_hours_item|
      start_hour_minutes = working_hours_item[0].to_i # Format: 1635 = 16 hours 35 minutes
      end_hour_minutes = working_hours_item[1].to_i

      start_hour_minutes < timezoned_hour_and_minutes &&
          timezoned_hour_and_minutes < end_hour_minutes
    end
  end

  def can_be_followed_up_now?
    account_timezone     = self.default_timezone_id || 'UTC'
    account_current_time = Time.now.in_time_zone(account_timezone)

    # Weekend
    return false if account_current_time.saturday? || account_current_time.sunday?

    account_working_start_time  = account_current_time.change(WORKING_DAY_START)
    account_working_end_time    = account_current_time.change(WORKING_DAY_END)

    account_current_time.between?(account_working_start_time, account_working_end_time)
  end


  def build_contacts_from_same_company params={}
      company_members = REDIS_FOR_ACCOUNTS_CACHE.get(self.company_hash.try(:[], 'name'))

      if company_members.present?
        company_members = JSON.parse(company_members)
        company_members.reject!{ |u| u['email'] == self.email }
        company_members.each  do |contact|
          contact[:email] = contact['email']
          contact[:account_email] = contact[:email]
        end
      end

      self.contacts_from_same_company = company_members || []
    #end
  end

  def self.get_active_account_emails params={}
    if params[:detailed]
      self.accounts_cache(mode: "light").values
    else
      self.accounts_cache(mode: "light").keys
    end
  end

  def all_emails
    if email.present?
      [email] + email_aliases
    else
      []
    end
  end

  def client_info
    info = ""
    info += "\nCompany: #{self.company_hash['name']}" if self.company_hash.present?
    info += "\nMeeting delay: #{self.delay_between_appointments} min" if self.delay_between_appointments.present?
    info += "\nMobile: #{self.mobile_number}" if self.mobile_number.present?
    info += "\nLandline: #{self.landline_number}" if self.landline_number.present?
    info += "\nSkype: #{self.skype}" if self.skype.present?
    info += "\nMeans of transport: #{self.means_of_transport}" if self.means_of_transport.present?

    main_address = self.addresses.find{|add| add['is_main_address']}
    if main_address.present?
      info += "\nMain Address: #{main_address['address']}"
    end

    offices_addresses = self.addresses.select{|addr| addresse_kind_dispatcher(addr) == "office" && !addr['is_main_address']}.map do |add|
      "\nOffice: #{add['address']}" if add['address'].present?
    end.compact.join('')
    info += offices_addresses
    agencies_addresses = self.addresses.select{|addr| addresse_kind_dispatcher(addr) == "agency" && !addr['is_main_address']}.map do |add|
      "\nAgency: #{add['address']}" if add['address'].present?
    end.compact.join('')
    info += agencies_addresses
    utc_offset = ActiveSupport::TimeZone.new(self.default_timezone_id).utc_offset/3600.0
    utc_offset = (utc_offset.to_i == utc_offset)?(utc_offset.to_i):(utc_offset)
    info += "\nDefault timezone: #{self.default_timezone_id} (GMT#{(utc_offset>=0)?"+#{utc_offset}":"#{utc_offset}"})"

    info
  end

  def serializable_hash
    self.to_json
  end

  def self.accounts_cache params={}
    if params[:mode] == "light"
      JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get("accounts_cache_light") || "{}")
    else
      JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get("accounts_cache") || "{}")
    end
  end

  def self.users_with_lost_access
    Set.new(REDIS_FOR_ACCOUNTS_CACHE.smembers('users_calendar_access_lost'))
  end

  def self.accounts_cache_for_email email
    JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get(email) || "{}")
  end

  def self.is_synced?(account_email)
    sync_limit_date = (ENV['LIMIT_DURATION_FOR_SYNCING_TAG'] || 4).to_i.minutes.ago
    account_cache = self.accounts_cache_for_email(account_email)
    return false if account_cache.blank?

    # We consider synced a calendar which is not on calendar server
    return true unless account_cache["using_calendar_server"]

    last_sync_date = DateTime.parse(account_cache["last_sync_date"]) rescue nil
    return false if last_sync_date.nil?
    last_sync_date > sync_limit_date
  end

  def self.not_synced?(account_email)
    !self.is_synced?(account_email)
  end

  def find_calendar_login_with_rule_data rule_data
    computed_rules = (self.calendar_logins || []).map{|calendar_login|
      {
          calendar_login: calendar_login,
          computed_rule: Account.compute_rule(calendar_login['rule'], rule_data)
      }
    }
    computed_rules.select{|cr|
      cr[:computed_rule] ==  RULE_VALIDATED
    }.first.try(:[], :calendar_login) ||
        computed_rules.select{|cr|
          cr[:computed_rule] ==  RULE_DEFAULT
        }.first.try(:[], :calendar_login)
  end

  def self.compute_rule calendar_login_rule, rule_data
    if calendar_login_rule.blank?
      RULE_DEFAULT
    else
      if calendar_login_rule.split("|").select{|rule_item|
        email_alias_in_rule = rule_item.gsub("EMAIL_ALIAS=", "")
        rule_data[:email_alias] == email_alias_in_rule
      }.length > 0
        RULE_VALIDATED
      else
        RULE_UNVALIDATED
      end
    end
  end

  def self.migrate_account_email origin_email, target_email
    #mts = MessagesThread.where(account_email: origin_email).includes(messages: :message_classifications)
    other_mt_ids = MessageClassification.where("attendees LIKE ?", "%#{origin_email}%").includes(:message).map{|mc| mc.message && mc.message.messages_thread_id}
    #mts += MessagesThread.includes(messages: [:message_classifications]).where(id: other_mt_ids.compact)

    ActiveRecord::Base.transaction do
      MessagesThread.includes(messages: [:message_classifications]).where('account_email = ? OR id IN (?)', origin_email, other_mt_ids.compact.uniq).find_in_batches.each do |messages_threads|
        messages_threads.each do |mt|
          if mt.account_email == origin_email
            mt.update_attribute :account_email, target_email
          end

          mt.messages.map(&:message_classifications).flatten.each do |mc|
            attendees = JSON.parse(mc.attendees || "[]")
            attendees.each{|att|
              if att['account_email'] == origin_email
                att['account_email'] = target_email
              end
            }
            constraints_data = JSON.parse(mc.constraints_data || "[]")
            constraints_data.each do |constraint|
              if constraint['attendee_email'] == origin_email && !attendees.map{|att| att['email']}.include?(constraint['attendee_email'])
                constraint['attendee_email'] = target_email
              end
            end
            mc.attendees = attendees.to_json
            mc.constraints_data = constraints_data.to_json
            mc.save
          end
        end
      end
    end
  end

  def self.migrate_events account_email, old_username, new_username
    jas = MessagesThread.where(account_email: account_email).includes(messages: {message_classifications: :julie_action}).map(&:messages).flatten.map(&:message_classifications).flatten.map(&:julie_action)

    creation_jas = jas.select { |ja| ja.events != "[]" }
    creation_jas.each do |creation_ja|
      creation_ja.events = JSON.parse(creation_ja.events).map do |event|
        if event['calendar_login_username'] == old_username
          event['calendar_login_username'] = new_username
        end
        event
      end.to_json
      creation_ja.save
    end

    scheduled_jas = jas.select { |ja| ja.event_id && ja.calendar_login_username == old_username }
    scheduled_jas.each do |scheduled_ja|
      scheduled_ja.update_attribute :calendar_login_username, new_username
    end
  end

  def is_in_circle_of_trust?(email)
    self.circle_of_trust.present? && ( self.circle_of_trust['trusted_emails'].include?(email) || ApplicationHelper.email_in_domain?(self.circle_of_trust['trusted_domains'], email) )
  end

  private

  def addresse_kind_dispatcher(address)
    address['kind'] ||address['type']
  end

  def self.get_account_details account_email, params={}
    if params[:accounts_cache]
      params[:accounts_cache][account_email]
    else
      Account.accounts_cache_for_email account_email
    end
  end
end