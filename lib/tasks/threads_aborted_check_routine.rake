namespace :messages_threads do
  
  task :threads_aborted_check_routine => :environment do |t|
    CheckThreadsAbortedRoutineWorker.enqueue
  end
end