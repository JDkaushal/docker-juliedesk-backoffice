class EmailServerInterface < BaseApiCaller

  ENDPOINTS = {
      fetch_ics: {type: :get, url: '/messages/get_attachment'}.freeze
  }.freeze

  def initialize
    super(HTTP.auth(ENV['EMAIL_SERVER_API_KEY']))
  end

  def build_request(key, data = {})
    super(key, data)
  end

  private

  def get_host_endpoint
    EmailServer::API_BASE_PATH
  end

  def compute_endpoint(key, data)
    endpoint_infos = ENDPOINTS[key]
    raise EndPointUnknown if endpoint_infos.blank?

    url = endpoint_infos[:url]

    {
        type: endpoint_infos[:type],
        url: "#{get_host_endpoint}#{url}"
    }
  end
end