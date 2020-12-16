namespace :daily_report do
  task :setex => :environment do |t|
   MessagesThread.generate_csv
  end
end