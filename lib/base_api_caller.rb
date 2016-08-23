class BaseApiCaller

  attr_accessor :ssl_context

  def initialize(client)
    @client = client

    @ssl_context = get_default_ssl_context
  end

  def build_request(key, data = nil)
    endpoint_infos = get_endpoint(key)
    type = endpoint_infos[:type]
    url = URI.parse(endpoint_infos[:url])

    if type == :get
      url = set_url_params(url, data)
    end

    dispatch_request(type, url, data)
  end

  def dispatch_request(type, url, data)
    result = self.send("execute_#{type}_request", @client, {url: url, data: data})

    #format_response(result.body)
    format_response(result)
  end

  private

  def get_endpoint(key)
    endpoint_infos = compute_endpoint(key)
    raise AIEndPointUnknown if endpoint_infos.blank?

    endpoint_infos
  end

  def compute_endpoint(key)
    raise 'Not implemented on the parent class'
  end

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
    http_client.get(params[:url], ssl_context: @ssl_context)
  end

  def execute_post_request(http_client, params)
    url = params.delete(:url)
    body = params[:data]
    http_client.post(url, json: body, ssl_context: @ssl_context)
  end

  def get_default_ssl_context
    ctx      = OpenSSL::SSL::SSLContext.new
    ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER

    ctx
  end

  def set_ssl_context(ssl_context)
    @ssl_context = ssl_context
  end

end