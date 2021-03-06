# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, File.join('log', 'cron.log')

every 1.day, :at => '1am', :roles => [:tasker] do
  rake 'operator_stats:compute'
end

every 1.minute, :roles => [:tasker] do
  rake 'dashboard_data:generate'
end

every 1.hour, :roles => [:tasker] do
  rake 'messages_threads:follow_up_check_routine'
end

every 1.day, :roles => [:tasker] do
  rake 'messages_threads:threads_aborted_check_routine'
end

every 5.minutes, :roles => [:tasker] do
  rake 'monitoring:monitor_inbox_threads'
end

every 1.day, :at => '3am', :roles => [:tasker] do
  rake 'archive:archive_old_threads'
end