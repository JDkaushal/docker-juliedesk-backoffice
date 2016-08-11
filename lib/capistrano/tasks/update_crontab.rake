desc "Update crontab with whenever"
task :update_crontab do
  on roles(:tasker) do
    within current_path do
      execute :bundle, :exec, "whenever --update-crontab"
    end
  end
end