class ClientContactsController < ApplicationController
  def fetch

    @contacts = ClientContact.where(client_email: params['client_email'], email: params['contacts_emails'])
    puts @contacts.to_json
    render json: @contacts
  end

  def synchronize
    success = true
    JSON.parse(params[:contacts]).each do |contact_params|
      puts contact_params
      if client_contact = ClientContact.find_by(client_email: params[:client_email], email: contact_params['email'])
        client_contact.update(
            first_name: contact_params['firstName'],
            last_name: contact_params['lastName'],
            usage_name: contact_params['usageName'],
            gender:  contact_params['gender'],
            is_assistant: contact_params['isAssistant'],
            assisted: contact_params['assisted'],
            assisted_by: contact_params['assistedBy'].to_json,
            company: contact_params['company'],
            timezone: contact_params['timezone'],
            landline: contact_params['landline'],
            mobile: contact_params['mobile'],
            skypeId:  contact_params['skypeId'],
            conf_call_instructions: contact_params['confCallInstructions'],
        )
      else
        client_contact = ClientContact.new(client_email: params[:client_email], email: contact_params['email'])
        client_contact.first_name = contact_params['firstName']
        client_contact.last_name = contact_params['lastName']
        client_contact.usage_name = contact_params['usageName']
        client_contact.gender =  contact_params['gender']
        client_contact.is_assistant = contact_params['isAssistant']
        client_contact.assisted = contact_params['assisted']
        client_contact.assisted_by = contact_params['assistedBy'].to_json
        client_contact.company = contact_params['company']
        client_contact.timezone = contact_params['timezone']
        client_contact.landline = contact_params['landline']
        client_contact.mobile = contact_params['mobile']
        client_contact.skypeId =  contact_params['skypeId']
        client_contact.conf_call_instructions = contact_params['confCallInstructions']
        client_contact.save
      end
    end

    render json: {success: success}
  end
end
