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
                :block_until_preferences_change,
                :mobile_number,
                :landline_number,
                :skype,
                :means_of_transport,
                :awaiting_current_notes,
                :contacts_from_same_company,
                :created_at,
                :complaints_count,
                :calendar_logins

  RULE_VALIDATED = "rule_validated"
  RULE_UNVALIDATED = "rule_unvalidated"
  RULE_DEFAULT = "rule_default"

  def self.create_from_email email, params={}
    #account_email = self.find_account_email email
    #return nil unless account_email

    cache = params[:accounts_cache] || self.accounts_cache
    return nil unless email
    data = get_account_details(email, {accounts_cache: cache})
    return nil unless data
    account = self.new
    account.email = data['email']
    account.appointments = data['appointments']
    account.addresses = data['addresses']
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
    account.skype = data['skype']
    account.means_of_transport = data['means_of_transport']
    account.only_admin_can_process = data['only_admin_can_process']
    account.block_until_preferences_change = data['block_until_preferences_change']

    account.calendar_logins = data['calendar_logins']


    begin
      account.created_at = DateTime.parse(data['created_at'])
    rescue
      account.created_at = DateTime.parse("1989-05-03")
    end


    account.complaints_count = data['complaints_count']

    account.build_contacts_from_same_company({accounts_cache: cache})

    account
  end

  def self.find_account_email email
    accounts = Account.get_active_account_emails detailed: true
    accounts.each do |account|
      if ([account['email']] + account['email_aliases']).map(&:downcase).include? "#{email}".downcase
        return account['email']
      end
    end

    nil
  end

  def number_to_call
    appointments.select{|appointment|
      appointment['type'] == "call"
    }.first.try(:[], 'number_to_call')
  end


  def build_contacts_from_same_company params={}

    cache = if params[:accounts_cache]
      params[:accounts_cache]
    else
      self.accounts_cache
    end

    self.contacts_from_same_company = cache.values.select{|account|
      self.company_hash &&
          account['company_hash'].try(:[], 'name') == self.company_hash['name'] &&
          account['email'] != self.email
    }.map{|account|
      {
          name: account['full_name'],
          email: account['email']
      }
    }
  end

  def self.get_active_account_emails params={}
    if params[:detailed]
      self.accounts_cache.values
    else
      self.accounts_cache.keys
    end
  end

  def all_emails
    [email] + email_aliases
  end

  def client_info
    info = ""
    info += "\nCompany: #{self.company_hash['name']}" if self.company_hash.present?
    info += "\nMobile: #{self.mobile_number}" if self.mobile_number.present?
    info += "\nLandline: #{self.landline_number}" if self.landline_number.present?
    info += "\nSkype: #{self.skype}" if self.skype.present?
    info += "\nMeans of transport: #{self.means_of_transport}" if self.means_of_transport.present?
    office_address = self.addresses.select{|addr| addr['kind'] == "office"}.map{|add| add['address']}.first
    info += "\nOffice: #{office_address}" if office_address.present?
    utc_offset = ActiveSupport::TimeZone.new(self.default_timezone_id).utc_offset/3600.0
    utc_offset = (utc_offset.to_i == utc_offset)?(utc_offset.to_i):(utc_offset)
    info += "\nDefault timezone: #{self.default_timezone_id} (GMT#{(utc_offset>=0)?"+#{utc_offset}":"#{utc_offset}"})"

    info
  end

  def serializable_hash
    self.to_json
  end

  def self.accounts_cache
    JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get("accounts_cache") || "{}")
  end

  def find_calendar_login_with_rule_data rule_data
    computed_rules = self.calendar_logins.map{|calendar_login|
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

  private



  def self.get_account_details account_email, params={}
    if params[:accounts_cache]
      params[:accounts_cache][account_email]
    else
      self.accounts_cache[account_email]
    end
  end
end