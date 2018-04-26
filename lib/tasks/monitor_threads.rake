namespace :monitoring do

  task :monitor_inbox_threads => :environment do |t|
    ProcessableThreadsService.run_verification!
  end

end