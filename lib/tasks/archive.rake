namespace :archive do
  task :archive_old_threads => :environment do |t|
    Archiver.archive_old_threads
  end
end
