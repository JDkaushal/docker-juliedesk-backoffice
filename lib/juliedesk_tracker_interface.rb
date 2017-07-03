class JuliedeskTrackerInterface < BaseApiCaller

  ENDPOINTS = {
      track: {type: :post, url: '/api/v1/track'}.freeze
  }.freeze

  def initialize
    super(HTTP.auth(nil).headers(:authorization => ENV['JD_BACKOFFICE_API_KEY']))
  end

  def build_request(key, data = {})
    super(key, data)
  end

  private

  def get_host_endpoint
    ENV['BACKOFFICE_ANALYTICS_BASE_PATH']
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