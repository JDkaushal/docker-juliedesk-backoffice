class AdminApiInterface < BaseApiCaller

  ENDPOINTS = {
      get_owner_event: {type: :get, url: '/api/v1/calendar_proxy/event_get'}.freeze,
      constraints_conflict: {type: :post, url: '/api/v1/calendar_proxy/constraints_conflict'}.freeze,
      set_awaiting_current_notes: {type: :post, url: '/api/v1/accounts/set_awaiting_current_notes'}.freeze,
      notify_blocked_threads: {type: :post, url: '/api/v1/calendar_access_lost/notify_email_blocked'}.freeze,
      get_blocking_users_calendars_renew_links: {type: :get, url: '/api/v1/calendar_access_lost/get_renew_access_links'}.freeze
  }.freeze

  def initialize
    super(HTTP.auth(ENV['JULIEDESK_APP_API_KEY']))
  end

  def build_request(key, data = {})
    super(key, data)
  end

  def self.constraints_conflicts constraints_data
    response = self.new.build_request(:constraints_conflict, {constraints_data: constraints_data})
    response['data']['conflict_present']
  end

  private

  def get_host_endpoint
    ENV['JULIEDESK_APP_BASE_PATH']
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