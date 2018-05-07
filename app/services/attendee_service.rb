class AttendeeService
  include TemplateGeneratorHelper

  def self.clean_and_categorize_clients!(attendees)
    accounts = Account.get_active_account_emails(detailed: true)
    attendees.map do |attendee|
      account = accounts.find { |account| ([account['email']] + (account['email_aliases'] || [])).map(&:downcase).include?(attendee.email) }
      account.blank? ? attendee : self.new(attendee).clean_and_categorize!(account)
    end
  end

  def self.set_usage_names!(attendees, params = {})
    locale    = params.fetch(:locale)
    is_formal = params.fetch(:is_formal)

    attendees.map do |attendee|
      self.new(attendee).set_usage_name!(locale, is_formal)
    end
  end


  def initialize(attendee)
    @attendee = attendee
  end

  def clean_and_categorize!(account)
    @attendee.email               &&= @attendee.email.gsub(" ", "")
    @attendee.account_email         = account['email']
    @attendee.usage_name            = account['usage_name']
    @attendee.first_name            = account['first_name']
    @attendee.last_name             = account['last_name']
    @attendee.landline              = account['landline_number']
    @attendee.mobile                = account['mobile_number']
    @attendee.skype_id              = account['skype']
    @attendee.confcall_instructions = account['confcall_instructions']
  end

  def set_usage_name!(locale, is_formal)
    @attendee.usage_name = get_usage_name({
      locale:     locale,
      formal:     is_formal,
      first_name: @attendee.first_name,
      last_name:  @attendee.last_name,
      gender:     "#{@attendee.gender}".first
    })
  end

end