class ClientSuccessTrackingHelpers
  require 'mixpanel-ruby'

  def self.async_track event_name, account_email, properties={}
    ClientSuccessTrackingWorker.enqueue(event_name, account_email, properties.merge({time: Time.now.to_i}))
  end

  def self.track event_name, account_email, properties
    analytics = SEGMENT_CLIENT
    account_id = Account.accounts_cache(mode: 'light').find{|email, infos| email.downcase == "#{account_email}".downcase}.try('[]', 1).try('[]', 'id')

    if account_id
      analytics.track(user_id: account_id, event: event_name, properties: properties)
    end

  end
end