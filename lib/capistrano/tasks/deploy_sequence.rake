# Rake task to make the deployment in sequence
###
# - Process the deployment server by server
# - Creates a signalization file when beginning the deployment and removes it at the end. This
# file is used to know if the service should be deactivated from Load Balancing or not
# - Once deployment is complete, restart all services (web servers and workers)


desc "Task that perform sequential deployment"
task :deploy_sequence do

  # Compile assets locally and upload to servers
  invoke 'deploy:assets:local_precompile'

  roles(:web).each do |server|
    puts server.hostname

    # Execute Deploy on each server one by one
    # Note that we pass an environment variable. If set, we will not launch restart tasks after the deploy task
    # but only after the deploy_sequence task
    sh "bundle exec cap --hosts=#{server.hostname} #{fetch(:rails_env)} deploy_with_signal deploy_sequence=true"

  end

  # Deploy other servers "normally"
  sh "bundle exec cap --roles=worker,tasker #{fetch(:rails_env)} deploy deploy_sequence=true"

  # Cleanup old assets
  invoke 'deploy:local_cleanup_assets'
end


desc "Actual deployment without restarting service"
task :deploy_with_signal do
  on roles(:all), in: :sequence, wait: 5 do

    signal_flag_dir = release_path.join('tmp/pids')
    signal_flag = release_path.join('tmp/pids/deploy_in_progress')

    # Set configuration in progress flag file if directory has already been created
    if test "[ -d " + signal_flag_dir.to_s + " ]"
      execute "touch " + signal_flag.to_s
    end

    # Invoke "normal deployment"
    invoke 'deploy'

    # Remove configuration in progress flag file
    if test "[ -d " + signal_flag_dir.to_s + " ]"
      execute "rm  " + signal_flag.to_s
    end

  end
end

before :deploy_sequence, 'lock:check'
after :deploy_sequence, 'lock:release'
