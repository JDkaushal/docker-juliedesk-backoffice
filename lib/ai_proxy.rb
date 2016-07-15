class AiProxy

  AI_ENDPOINTS = {
      parse_human_civilities: { type: :get, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/firstlastnames/' }.freeze,
      initiate_planning:      { type: :get, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/planning/initiate/'}.freeze,
      fetch_planning:         { type: :get, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/planning/get/'}.freeze,
      fetch_forecast:         { type: :get, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/planning/'}.freeze,
      fetch_forecast_emails:  { type: :get, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/forecastemails/'}.freeze,

      process_entity_main:    { type: :get, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/main/'}.freeze,
      process_entity_entities:    { type: :post, url: ENV['CONSCIENCE_API_BASE_PATH_V2'] + '/entities/'}.freeze,

      get_company_name:       { type: :post, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/companynames/' }.freeze,
      parse_sncf_ticket:      { type: :post, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/parsersncf/'}.freeze
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

    dispatch_request(type, url, data)
  end

  def dispatch_request(type, url, data)

    client = HTTP.auth(ENV['CONSCIENCE_API_KEY'])
    # url = "#{ENV['CONSCIENCE_API_BASE_PATH_V1']}/planning/?date=#{date.strftime('%Y-%m-%d')}"
    #
    # response = http.get(url)

    # client = HTTPClient.new(default_header: {
    #                           "Authorization" => ENV['CONSCIENCE_API_KEY']
    #                         })
    #
    # client.ssl_config.verify_mode = 0
    #
    # puts client.ssl_config.inspect

    result = self.send("execute_#{type}_request", client, {url: url, data: data})

    #format_response(result.body)
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
    if result.code < 200 || result.code >299
      raise AIError.new("#{result.status} \n\n #{result.body}")
    end

    result.parse
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