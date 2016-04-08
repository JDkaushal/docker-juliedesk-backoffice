namespace :ai do
  task :email_forecast => :environment do |t|

    AiEmailFlowForecast.fetch

    print('OK')
  end
end
