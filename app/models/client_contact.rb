class ClientContact < ActiveRecord::Base

  validates :client_email, presence: true

  def to_param
    self.client_email
  end

  def as_json(options)
    is_client = Account.find_account_email(self.email).present?
    {
      id: self.id,
      client_email: self.client_email,
      email: self.email,
      firstName: self.first_name,
      lastName: self.last_name,
      usageName: self.usage_name,
      gender: self.gender,
      isAssistant: self.is_assistant.to_s,
      assisted: self.assisted.to_s,
      assistedBy: self.assisted_by,
      company: self.company,
      timezone: self.timezone,
      landline: self.landline,
      mobile: self.mobile,
      skypeId: self.skypeId,
      confCallInstructions: self.conf_call_instructions,
      isClient: is_client.to_s
    }
  end
end
