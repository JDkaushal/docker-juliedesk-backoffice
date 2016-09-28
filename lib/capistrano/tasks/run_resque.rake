desc "Restart Resque"
task :run_resque do
  on roles(:worker) do
    within current_path do
      execute "/bin/bash", File.join(shared_path, "script", "stop_resque.sh")
      execute "/bin/bash", File.join(shared_path, "script", "start_resque.sh")
    end
  end
end