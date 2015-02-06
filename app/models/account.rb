class Account

  require 'net/http'

  attr_accessor :email, :calendar_nature, :appointments, :usage_name, :full_name, :email_aliases, :access_token, :raw_preferences, :current_notes

  def self.create_from_email email
    #account_email = self.find_account_email email
    #return nil unless account_email
    return nil unless email
    data = get_account_details email
    return nil unless data
    account = self.new
    account.email = data['email']
    account.calendar_nature = data['calendar_nature']
    account.appointments = data['appointments']
    account.usage_name = data['usage_name']
    account.full_name = data['full_name']
    account.email_aliases = data['email_aliases']
    account.access_token = data['access_token']
    account.raw_preferences = data['raw_preferences']
    account.current_notes = data['current_notes']
    account
  end

  def self.find_account_email email
    accounts = Account.get_active_account_emails detailed: true
    accounts.each do |account|
      if ([account['email']] + account['email_aliases']).include? email
        return account['email']
      end
    end

    nil
  end

  def self.get_active_account_emails params={}
    url = URI.parse("https://#{ApplicationHelper::JD_APP_HOST}/api/v1/accounts?access_key=gho67FBDJKdbhfj890oPm56VUdfhq8")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) {|http|
      http.request(req)
    }

    data = JSON.parse(res.body)
    if params[:detailed]
      data['data']['items']
    else
      data['data']['items'].map{|user| user['email']}
    end
  end

  def all_emails
    [email] + email_aliases
  end

  def calendar_url mode="create_event"
    params = {
        locale: "en",
        email: self.email,
        access_token: self.access_token || "undefined",
        mode: mode,
    }
    "chrome-extension://hfhablbcnnfghdnbhaphjllhmngndkha/calendar.html##{params.map{|k, v| "#{k}=#{v}"}.join("&")}"
  end

  private

  def self.get_account_details account_email
    begin
    url = URI.parse("https://#{ApplicationHelper::JD_APP_HOST}/api/v1/accounts/show/?email=#{account_email}&access_key=gho67FBDJKdbhfj890oPm56VUdfhq8")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) {|http|
      http.request(req)
    }

    data = JSON.parse(res.body)
    data['data']
    rescue
      nil
    end

  end
end