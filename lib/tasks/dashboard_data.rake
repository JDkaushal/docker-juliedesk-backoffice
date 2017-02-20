namespace :dashboard_data do
  task :compute => :environment do |t|
    DashboardDataGenerator.generate_data
  end
end