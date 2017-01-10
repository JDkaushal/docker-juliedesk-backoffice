module TemplateGeneratorHelper



  def get_suggest_dates_template template_data
    request("/api/v1/templates/suggest_dates", template_data)['data']
  end

  def get_say_hi_template template_data
    request("/api/v1/templates/say_hi", template_data)['data']
  end

  private

  def request path, body=nil
    uri = URI.parse("#{ENV['TEMPLATE_GENERATOR_BASE_PATH']}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(path)
    request.add_field('Content-Type', 'application/json')
    if body
      request.body = body.to_json
    end
    response = http.request(request)
    JSON.parse(response.body)
  end
end