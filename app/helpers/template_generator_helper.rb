module TemplateGeneratorHelper


  def get_wait_for_contact_template template_data
    request("/api/v1/templates/wait_for_contact", template_data)
  end

  def get_forward_to_support_template template_data
    "I FORWARD TO SUPPORT"
  end

  def get_forward_to_client_template template_data
    request("/api/v1/templates/forward_to_client", template_data)
  end

  def get_suggest_date_template template_data
    request("/api/v1/templates/suggest_date", template_data, { format: 'html' })
  end

  def get_suggest_dates_template template_data
    request("/api/v1/templates/suggest_dates", template_data)
  end

  def get_say_hi_template template_data
    request("/api/v1/templates/say_hi", template_data)
  end

  def get_usage_name template_data
    request("/api/v1/templates/usage_name", template_data)
  end

  def get_invitations_sent_template template_data
    request("/api/v1/templates/send_invitations", template_data)
  end

  def get_send_confirmation_template template_data
    request('/api/v1/templates/send_confirmation', template_data)
  end

  def get_client_unvailable_template template_data
    request('/api/v1/templates/client_unavailable', template_data)
  end

  def get_generic_error_template template_data
    request('/api/v1/templates/something_happened_error', template_data)
  end

  def get_ai_processing_error_template template_data
    request('/api/v1/templates/ai_cannot_process_request', template_data)
  end

  def get_ai_unprocessable_request_error_template(template_data)
    request('/api/v1/templates/ai_unprocessable_request', template_data, { format: 'html' })
  end

  def get_command_line_not_understood_template template_data
    request('/api/v1/templates/command_line_not_understood', template_data, { format: 'html' })
  end

  def get_no_available_slot_template template_data
    request('/api/v1/templates/no_available_slot', template_data, { format: 'html' })
  end

  private

  def request(path, body=nil, options = {})
    format = options.fetch(:format, 'text')
    uri = URI.parse("#{ENV['TEMPLATE_GENERATOR_BASE_PATH']}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(path)
    request.add_field('Content-Type', 'application/json')
    if body
      request.body = body.to_json
    end
    response = http.request(request)
    JSON.parse(response.body)['data'][format]
  end
end