class ClientContactsController < ApplicationController
  def fetch
    @contacts = ClientContact.where(client_email: params['client_email'], email: params['contacts_emails'])
    accounts_cache = Account.accounts_cache

    @contacts_infos = []
    @contacts_aliases = {}
    @contacts_companies = {}

    if params['contacts_emails'].present?
      params['contacts_emails'].each do |contact|
        if cache = accounts_cache[contact]
          @contacts_aliases[contact] = cache["email_aliases"]
          @contacts_companies[contact] = cache["company_hash"] ? cache["company_hash"]["name"] : ''
        end
      end
    end

    if @contacts && @contacts.size > 0
      @contacts.each do |contact|
        searched_email = contact.email

        @contacts_aliases.each do |aliased_email, aliases|
          if aliases.include?(contact.email)
            searched_email = aliased_email
            break
          end
        end

        if cache = accounts_cache[searched_email]
          fullname_splitted = cache['full_name'].split(' ')
          account = {
              id: contact.id,
              client_email: contact.client_email,
              email: contact.email,
              firstName: fullname_splitted[0],
              lastName: (fullname_splitted.slice(1, fullname_splitted.size) || []).join(' '),
              usageName: cache['usage_name'],
              gender: contact.gender,
              isAssistant: contact.is_assistant.to_s,
              assisted: contact.assisted.to_s,
              assistedBy: contact.assisted_by,
              company: cache['company_hash'] ? cache['company_hash']["name"] : '',
              timezone: cache['default_timezone_id'],
              landline: cache['landline_number'],
              mobile: cache['mobile_number'],
              skypeId: cache['skype'],
              confCallInstructions: cache['confcall_instructions'],
              isClient: "true"
          }
        else
          account = {
              id: contact.id,
              client_email: contact.client_email,
              email: contact.email,
              firstName: contact.first_name,
              lastName: contact.last_name,
              usageName: contact.usage_name,
              gender: contact.gender,
              isAssistant: contact.is_assistant.to_s,
              assisted: contact.assisted.to_s,
              assistedBy: contact.assisted_by,
              company: contact.company,
              timezone: contact.timezone,
              landline: contact.landline,
              mobile: contact.mobile,
              skypeId: contact.skypeId,
              confCallInstructions: contact.conf_call_instructions,
              isClient: "false"
          }
        end
        @contacts_infos.push(account)
      end
    else
      if params['contacts_emails'].present?
        params['contacts_emails'].each do |contact_email|
          searched_email = contact_email

          @contacts_aliases.each do |aliased_email, aliases|
            if aliases.include?(contact_email)
              searched_email = aliased_email
              break
            end
          end

          if cache = accounts_cache[searched_email]
            fullname_splitted = cache['full_name'].split(' ')
            @contacts_infos.push({
                 client_email: params['client_email'],
                 email: contact_email,
                 firstName: fullname_splitted[0],
                 lastName: (fullname_splitted.slice(1, fullname_splitted.size) || []).join(' '),
                 usageName: cache['usage_name'],
                 gender: "?",
                 isAssistant: "false",
                 assisted: "false",
                 assistedBy: nil,
                 company: cache['company_hash'] ? cache['company_hash']["name"] : '',
                 timezone: cache['default_timezone_id'],
                 landline: cache['landline_number'],
                 mobile: cache['mobile_number'],
                 skypeId: cache['skype'],
                 confCallInstructions: cache['confcall_instructions'],
                 isClient: "true"
             })
          end
        end
      end
    end

    render json: {contacts: @contacts_infos, aliases: @contacts_aliases, companies: @contacts_companies}
  end

  def synchronize
    success = true
    JSON.parse(params[:contacts]).each do |contact_params|

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
