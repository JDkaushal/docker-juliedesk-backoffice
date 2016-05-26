namespace :ai do
  task :email_forecast => :environment do |t|
    now = Time.now

    # We run the forecast every Sunday at 2AM (UTC)
    # It will predict the email incoming flow for the next two weeks
    if now.wday == 0
      AiEmailFlowForecast.fetch(now)
    end

    print('OK')
  end
end
