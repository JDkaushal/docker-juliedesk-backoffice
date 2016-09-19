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
                :have_priority,
                :auto_follow_up_enabled,
                :restaurant_booking_enabled,
                :julie_aliases,
                :using_calendar_server

  RULE_VALIDATED = "rule_validated"
  RULE_UNVALIDATED = "rule_unvalidated"
  RULE_DEFAULT = "rule_default"

  def self.create_from_email email, params={}
    cache = params[:accounts_cache]# || self.accounts_cache
    return nil unless email.present?
    data = get_account_details(email, {accounts_cache: cache})
    return nil unless data.present?
    account = self.new
    account.email = data['email']
    account.appointments = data['appointments']
    account.addresses = data['addresses']
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
    account.have_priority = data['have_priority']
    account.auto_follow_up_enabled = data['auto_follow_up_enabled']
    account.restaurant_booking_enabled = data['restaurant_booking_enabled']
    account.julie_aliases = data['julie_aliases']
    account.using_calendar_server = data['using_calendar_server']

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

    account
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


  def build_contacts_from_same_company params={}

    # if params[:accounts_cache]
    #   name_str = 'name'.freeze
    #
    #   self.contacts_from_same_company = params[:accounts_cache].values.select{|account|
    #     self.company_hash &&
    #         account['company_hash'].try(:[], name_str) == self.company_hash[name_str] &&
    #         account['email'] != self.email
    #   }.map{|account|
    #     julie_alias = account['julie_aliases'] && account['julie_aliases'].first
    #     json_julie_alias = julie_alias ? {email: julie_alias['email'], displayName: "#{julie_alias['first_name']} #{julie_alias['last_name']}"} : nil
    #
    #     {
    #         name: account['full_name'],
    #         email: account['email'],
    #         isClient: 'true'.freeze,
    #         assisted: "#{json_julie_alias.present?}",
    #         assistedBy: json_julie_alias
    #     }
    #   }
    # else
      #We retrieve the other users of the same company from the cache directly
      company_members = REDIS_FOR_ACCOUNTS_CACHE.get(self.company_hash.try(:[], 'name'))

      if company_members.present?
        company_members = JSON.parse(company_members)
        company_members.reject!{ |u| u['email'] == self.email }
        company_members.each {|contact| contact[:email] = contact['email']}
      end

      self.contacts_from_same_company = company_members || []
    #end
  end

  def self.get_active_account_emails params={}
    if params[:detailed]
      self.accounts_cache.values
    else
      self.accounts_cache.keys
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
    offices_addresses = self.addresses.select{|addr| addr['kind'] == "office"}.map do |add|
      "\nOffice: #{add['address']}" if add['address'].present?
    end.compact.join('')
    info += offices_addresses
    agencies_addresses = self.addresses.select{|addr| addr['kind'] == "agency"}.map do |add|
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

  def self.accounts_cache_for_email email
    JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get(email) || "{}")
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
    mts = MessagesThread.where(account_email: origin_email).includes(messages: :message_classifications)
    other_mt_ids = MessageClassification.where("attendees LIKE ?", "%#{origin_email}%").includes(:message).map{|mc| mc.message.messages_thread_id}
    mts += MessagesThread.where(id: other_mt_ids)

    mts.each do |mt|
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

  private

  def self.get_account_details account_email, params={}
    if params[:accounts_cache]
      params[:accounts_cache][account_email]
    else
      Account.accounts_cache_for_email account_email
    end
  end
end