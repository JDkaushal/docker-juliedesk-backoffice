class ClientContact < ActiveRecord::Base

  validates :client_email, presence: true

  def to_param
    self.client_email
  end

  def as_json(options)
    client_account = Account.create_from_email(self.email)

    if client_account.present?
      fullname_splitted = client_account.full_name.split(' ')

      {
        id: self.id,
        client_email: self.client_email,
        email: self.email,
        firstName: fullname_splitted[0],
        lastName: (fullname_splitted.slice(1, fullname_splitted.size) || []).join(' '),
        usageName: client_account.usage_name,
        gender: self.gender,
        isAssistant: self.is_assistant.to_s,
        assisted: self.assisted.to_s,
        assistedBy: self.assisted_by,
        company: client_account.company_hash ? client_account.company_hash["name"] : '',
        timezone: client_account.default_timezone_id,
        landline: client_account.landline_number,
        mobile: client_account.mobile_number,
        skypeId: client_account.skype,
        confCallInstructions: client_account.confcall_instructions,
        isClient: "true"
      }

    else
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
        isClient: "false"
      }
    end
  end
end
