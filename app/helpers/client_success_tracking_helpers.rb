class ClientSuccessTrackingHelpers
  require 'mixpanel-ruby'


  if Rails.env.development?
    #silence local SSL errors
    Mixpanel.config_http do |http|
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end

  def self.async_track event_name, account_email, properties={}
    ClientSuccessTrackingWorker.enqueue(event_name, account_email, properties.merge({time: Time.now.to_i}))
  end

  def self.track event_name, account_email, properties
    puts "Going to track #{event_name} for user #{account_email}"
    puts "Properties: #{properties}"

    tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_FOR_CLIENT_SUCCESS_TOKEN'])

    puts tracker.track("#{account_email}", event_name, properties)

    puts "Done"
  end
end