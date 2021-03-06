class ClientContactsController < ApplicationController

  def fetch
    @contacts = ClientContact.where(client_email: params['client_email'], email: params['contacts_emails'])
    #accounts_cache = Account.accounts_cache
    accounts_cache_light = Account.accounts_cache(mode: 'light')

    @contacts_infos = []
    @contacts_aliases = {}
    @contacts_companies = {}

    if params['contacts_emails'].present?
      params['contacts_emails'].each do |contact|
        if cache = accounts_cache_light.find{|email, infos| email.downcase == contact.downcase}.try('[]', 1)
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

        cache = ClientContact.fetch_redis(searched_email)

        if cache && cache['configured'] && cache['subscribed']

          fullname_splitted = cache['full_name'].split(' ')

          # We convert subscribed and configured boolean to their string counterpart for retro compatibility purposes
          account = {
              id: contact.id,
              client_email: contact.client_email,
              email_aliases: cache['email_aliases'],
              email: contact.email,
              firstName: fullname_splitted[0],
              lastName: (fullname_splitted.slice(1, fullname_splitted.size) || []).join(' '),
              usageName: cache['usage_name'],
              gender: contact.gender,
              isAssistant: "false",
              assisted: "false",
              assistedBy: nil,
              company: cache['company_hash'] ? cache['company_hash']["name"] : '',
              timezone: cache['default_timezone_id'],
              landline: cache['landline_number'],
              mobile: cache['mobile_number'],
              skypeId: cache['skype'],
              confCallInstructions: cache['confcall_instructions'],
              subscribed: cache['subscribed'].to_s,
              configured: cache['configured'].to_s,
              isClient: 'true',
              needAIConfirmation: contact.need_ai_confirmation,
              aIHasBeenConfirmed: contact.ai_has_been_confirmed
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
              isClient: "false",
              needAIConfirmation: contact.need_ai_confirmation,
              aIHasBeenConfirmed: contact.ai_has_been_confirmed
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

          cache = ClientContact.fetch_redis(searched_email)

          if cache && cache['configured'] && cache['subscribed']
            fullname_splitted = cache['full_name'].split(' ')

            @contacts_infos.push({
               client_email: params['client_email'],
               email_aliases: cache['email_aliases'],
               email: contact_email,
               firstName: fullname_splitted[0],
               lastName: (fullname_splitted.slice(1, fullname_splitted.size) || []).join(' '),
               usageName: cache['usage_name'],
               gender: "Unknown",
               isAssistant: "false",
               assisted: "false",
               assistedBy: nil,
               company: cache['company_hash'] ? cache['company_hash']["name"] : '',
               timezone: cache['default_timezone_id'],
               landline: cache['landline_number'],
               mobile: cache['mobile_number'],
               skypeId: cache['skype'],
               confCallInstructions: cache['confcall_instructions'],
               subscribed: cache['subscribed'].to_s,
               configured: cache['configured'].to_s,
               isClient: 'true'
             })
          end
        end
      end
    end

    if params['contacts_emails'].present?
      company_julie_alias = ClientContact.fetch_companies_julie_alias

      @contacts_infos.each do |contact_infos|
        contact_infos_company = contact_infos[:company]
        if contact_infos_company.present? &&
          contact_infos.is_a?(Hash) &&
          contact_infos[:isClient] == 'true' &&
          company_julie_alias.is_a?(Hash) &&
          company_julie_alias_infos = company_julie_alias[contact_infos_company]

          contact_infos[:assisted] = "true"
          contact_infos[:assistedBy] = company_julie_alias_infos
        end
      end

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

      fields_to_update = {
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
          need_ai_confirmation: contact_params['needAIConfirmation'],
          ai_has_been_confirmed: contact_params['aIHasBeenConfirmed'],
      }
      if contact_params['isClient']
        fields_to_update.delete(:timezone)
      end
      if client_contact = ClientContact.find_by(client_email: params[:client_email], email: contact_params['email'])
        client_contact.update(fields_to_update)
      else
        client_contact = ClientContact.new(client_email: params[:client_email], email: contact_params['email'])
        client_contact.assign_attributes(fields_to_update)
        client_contact.save
      end

      if contact_params['companyUpdated']
        domain = contact_params['email'].split('@')[-1]
        company_domain_assoc = CompanyDomainAssociation.find_or_initialize_by(domain: domain)
        if company_domain_assoc.is_editable
          company_domain_assoc.company_name = contact_params['company']
          company_domain_assoc.save
        end
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

    if accounts_cache_light.find{|email, infos| email.downcase == params[:email].downcase && infos['configured'] && infos['subscribed'] }.try('[]', 1)
      is_client = true
    else
      accounts_cache_light.each do |email, account|
        if account["email_aliases"].include?(params[:email]) && account['configured'] && account['subscribed']
          is_client = true
          break
        end
      end
    end

    if @contact
      response = {
        email: @contact.email,
        company: @contact.company,
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

  def ai_parse_contact_civilities
    render json: AI_PROXY_INTERFACE.build_request(:parse_human_civilities, { fullname: params[:fullname], at: params[:email]})

  rescue AiProxy::TimeoutError
    render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def ai_get_company_name
    domain = Mail::Address.new(params[:contact_address]).domain

    if domain.nil?
      render json: { error_code: "AI:GET_COMPANY_NAME:INVALID_ADDRESS", message: "Contact address is invalid" }, status: :unprocessable_entity
      return
    end

    if CompanyDomainAssociationFilter::Filter.new.filter(domain)
      result = {identification: 'filtered_domain', company: '', database_id: -1, database_domain: domain, security_check_is_empty: true}
    else
      record = CompanyDomainAssociation.find_by(domain: domain)

      if record.present?
        result = {identification: 'backoffice_database', company: record.company_name, database_id: record.id, database_domain: domain, security_check_is_empty: record.company_name.blank?}
      else

        begin
          result = AI_PROXY_INTERFACE.build_request(:get_company_name, { address: params[:contact_address], message: params[:message_text] })
        rescue AiProxy::TimeoutError
          render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
          return
        end

        unless result[:error]
          # When the call fail, we store an empty string to avoid calling the API against on subsequent calls
          company_name = result['identification'] == 'fail' ? '' : result['company']
          CompanyDomainAssociation.find_or_create_by(domain: domain, company_name: company_name)
        end
      end
    end

    render json: result
  end
end
