class Api::V1::ClientContactsController < Api::ApiV1Controller


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
          result = AiProxy.new.build_request(:get_company_name, { address: params[:contact_address], message: params[:message_text] })
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