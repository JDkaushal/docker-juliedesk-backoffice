class AiProxy

  AI_ENDPOINTS = {
      parse_human_civilities: { type: :get, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/firstlastnames/' }.freeze,
      get_company_name:       { type: :post, url: ENV['CONSCIENCE_API_BASE_PATH_V1'] + '/companynames/' }.freeze
  }.freeze

  def self.get_endpoint(key)
    endpoint_infos = AI_ENDPOINTS[key]
    raise AIEndPointUnknown if endpoint_infos.blank?

    endpoint_infos
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

    client = HTTPClient.new(default_header: {
                                "Authorization" => ENV['CONSCIENCE_API_KEY']
                            })

    client.ssl_config.verify_mode = 0

    result = self.send("execute_#{type}_request", client, {url: url, data: data})

    format_response(result.body)
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
    JSON.parse(result)
  end

  def execute_get_request(http_client, params)
    http_client.get(params[:url])
  end

  def execute_post_request(http_client, params)
    url = params.delete(:url)
    body = params[:data].to_json
    http_client.post(url, body)
  end

end

class AIError < StandardError; end
class AIEndPointUnknown < AIError
  def message
    'The specified endpoint has not been registered'
  end
end