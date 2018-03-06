module EventsManagement
  class BaseInterface < BaseApiCaller

    ENDPOINTS = {
        create: {type: :post, url: '/api/v1/calendar_proxy/event_create'}.freeze,
        update: {type: :post, url: '/api/v1/calendar_proxy/event_update'}.freeze,
        fetch:  {type: :get,  url: '/api/v1/calendar_proxy/event_get'}.freeze
    }.freeze

    def initialize
      super(HTTP.auth(ENV['JULIEDESK_APP_API_KEY']))
    end

    def build_request(key, data = nil)
      super(key, data)
    end

    private

    def get_host_endpoint
      ENV['JULIEDESK_APP_HOST']
    end

    def compute_endpoint(key, data=nil)
      endpoint_infos = ENDPOINTS[key]
      raise AIEndPointUnknown if endpoint_infos.blank?

      {
          type: endpoint_infos[:type],
          url: "#{get_host_endpoint}#{endpoint_infos[:url]}"
      }
    end

  end

end