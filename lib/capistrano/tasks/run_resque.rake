desc "Restart Resque"
task :run_resque do
  on roles(:worker) do
    within current_path do
      execute "/bin/bash", File.join(shared_path, "script", "stop_resque.sh"), fetch(:resque_pid_file)
      execute "/bin/bash", File.join(shared_path, "script", "start_resque.sh"), fetch(:resque_pid_file)
    end
  end
end