namespace :dashboard_data do
  task :generate => :environment do |t|
    DashboardDataGenerator.generate_data
  end
end