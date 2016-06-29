namespace :messages_threads do

  # TODO create the scheduler Job in heroku to run this

  task :follow_up_check_routine => :environment do |t|
    Delayed::Job.enqueue FollowUp::CheckRoutineJob.new
  end

end