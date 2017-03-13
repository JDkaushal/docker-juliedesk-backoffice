class AiProxy
  class TimeoutError < Exception ; end

  AI_ENDPOINTS = {
      parse_human_civilities: { type: :get, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v3/firstlastnames/' }.freeze,
      initiate_planning:      { type: :get, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/planning/initiate/'}.freeze,
      fetch_planning:         { type: :get, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/planning/get/'}.freeze,
      fetch_forecast:         { type: :get, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/planning/'}.freeze,
      fetch_forecast_emails:  { type: :get, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/forecastemails/'}.freeze,
      ask_julia:              { type: :get, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/julia/'}.freeze,

      process_entity_main:    { type: :get, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/main/'}.freeze,
      process_entity_entities:    { type: :post, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v2/entities/'}.freeze,

      get_company_name:       { type: :post, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/companynames/' }.freeze,
      parse_sncf_ticket:      { type: :post, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/parsersncf/'}.freeze,

      fetch_dates_suggestions: { type: :post, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/calendar/suggest_dates/' }.freeze,
      send_dates_suggestions_learning_data: { type: :post, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/calendar/validated_dates/' }.freeze,

      verify_dates: { type: :post, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/calendar/validate_dates/' }.freeze,

      calendar_classification: { type: :post, url: ENV['CONSCIENCE_BASE_PATH'] + '/api/v1/calendar/classification/' }.freeze,
  }.freeze

  def self.get_endpoint(key)
    endpoint_infos = AI_ENDPOINTS[key]
    raise AIEndPointUnknown if endpoint_infos.blank?

    endpoint_infos
  end

  def initialize(options={})
    @format_response = options.delete(:format_response)

    @format_response = true if @format_response.nil?
  end

  def build_request(key, data = nil)
    endpoint_infos = AiProxy.get_endpoint(key)
    type = endpoint_infos[:type]
    url = URI.parse(endpoint_infos[:url])

    if type == :get
      url = set_url_params(url, data)
    end

    Timeout::timeout(ENV['CONSCIENCE_API_TIMEOUT'].to_i || 20) do
      dispatch_request(type, url, data)
    end

  rescue Timeout::Error => e
    raise TimeoutError.new(e)
  end

  def dispatch_request(type, url, data)
    client = HTTP.auth(ENV['CONSCIENCE_API_KEY'])
    result = self.send("execute_#{type}_request", client, {url: url, data: data})
    @format_response ? format_response(result) : result
  end

  private

  def set_url_params(url, params)
    params.each do |k, v|
      new_query_ar = URI.decode_www_form(url.query || '') << [k, v]
      url.query = URI.encode_www_form(new_query_ar)
    end
    url
  end

  def format_response(result)
    #JSON.parse(result)
    if result.code >= 200 && result.code <= 299
      result.parse
    else
      {
          error: true,
          http_status: result.code
      }
      #raise AIError.new("#{result.status} \n\n #{result.body}")
    end

  end

  def execute_get_request(http_client, params)
    http_client.get(params[:url], ssl_context: get_ssl_context)
    #http_client.get(params[:url])
  end

  def execute_post_request(http_client, params)
    url = params.delete(:url)
    #body = params[:data].to_json
    body = params[:data]
    http_client.post(url, json: body, ssl_context: get_ssl_context)
    #http_client.post(url, body)
  end

  def get_ssl_context
    ctx      = OpenSSL::SSL::SSLContext.new
    ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE

    ctx
  end

end

class AIError < StandardError; end
class AIEndPointUnknown < AIError
  def message
    'The specified endpoint has not been registered'
  end
end