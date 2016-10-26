desc "Update crontab with whenever"
task :update_crontab do
  on roles(:tasker) do
    within current_path do
      execute :bundle, :exec, "whenever --update-crontab #{fetch(:application)}"
    end
  end
end