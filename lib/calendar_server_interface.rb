class CalendarServerInterface < BaseApiCaller

  ENDPOINTS = {
      get_owner_event: {type: :get, url: '/api/v1/events/get_owner_event'}.freeze,
      get_event: {type: :get, url: '/api/v1/events/get_event'}.freeze
  }.freeze

  def initialize
    super(HTTP.auth(ENV['CALENDAR_SERVER_AUTHORIZATION']))
  end

  def build_request(key, data = {})
    super(key, data)
  end

  private

  def get_host_endpoint
    ENV['CALENDAR_SERVER_BASE_PATH']
  end

  def compute_endpoint(key, data)
    endpoint_infos = ENDPOINTS[key]
    raise AIEndPointUnknown if endpoint_infos.blank?

    {
        type: endpoint_infos[:type],
        url: "#{get_host_endpoint}#{endpoint_infos[:url]}"
    }
  end
end