class ClientContactsController < ApplicationController
  def fetch
    @contacts = ClientContact.where(client_email: params['client_email'], email: params['contacts_emails'])
    accounts_cache = Account.accounts_cache
    accounts_cache_light = Account.accounts_cache(mode: 'light')

    @contacts_infos = []
    @contacts_aliases = {}
    @contacts_companies = {}

    if params['contacts_emails'].present?
      params['contacts_emails'].each do |contact|
        if cache = accounts_cache_light[contact]
          @contacts_aliases[contact] = cache["email_aliases"]
          @contacts_companies[contact] = cache["company_hash"] ? cache["company_hash"]["name"] : ''
        else
          accounts_cache_light.each do |email, account|
            if account["email_aliases"].include?(contact)
              @contacts_aliases[email] = account["email_aliases"]
              @contacts_companies[email] = account["company_hash"] ? account["company_hash"]["name"] : ''
            end
          end
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

    if params['contacts_email'].present?
      not_found_contacts_emails = params['contacts_emails'] - @contacts_infos.map{|c| c[:email]}

      not_found_contacts_emails.each do |contact_email|
        if(contact = ClientContact.where(email: contact_email).first)
          @contacts_infos.push({
            email: contact.email,
            firstName: contact.first_name,
            lastName: contact.last_name,
            gender: contact.gender
          })
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

  def emails_suggestions
    # We query postgres for a regex pattern seraching for all contacts having an email that begins by the sub string passed as parameter
    @emails_suggestions = ClientContact.where("email ~* ?", '^' + params[:sub_string]).map(&:email).uniq

    render json: @emails_suggestions
  end

  def fetch_one
    @contact = ClientContact.find_by(client_email: params[:client_email], email:params[:email])

    accounts_cache_light = Account.accounts_cache(mode: 'light')

    is_client = false

    if accounts_cache_light[params[:email]]
      is_client = true
    else
      accounts_cache_light.each do |email, account|
        if account["email_aliases"].include?(params[:email])
          is_client = true
          break
        end
      end
    end

    if @contact
      response = {
        email: @contact.email,
        firstName: @contact.first_name,
        lastName: @contact.last_name,
        gender: @contact.gender,
        usageName: @contact.usage_name,
        isAssistant: @contact.is_assistant,
        assisted: @contact.assisted,
        assistedBy: @contact.assisted_by,
        timezone: @contact.timezone,
        landline: @contact.landline,
        mobile: @contact.mobile,
        skypeId: @contact.skypeId,
        confCallInstructions: @contact.conf_call_instructions,
        isClient: is_client
      }
    else
      if(@contact = ClientContact.find_by_email(params[:email]))
        response = {
          email: @contact.email,
          firstName: @contact.first_name,
          lastName: @contact.last_name,
          gender: @contact.gender,
          isClient: is_client
        }
      else
        response = {error: 'Contact Not Found'}
      end
    end

    render json: response
  end
end
