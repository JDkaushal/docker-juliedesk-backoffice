desc "Update crontab with whenever"
task :update_crontab do
  on roles(:tasker) do
    within current_path do
      execute :bundle, :exec, "whenever --set 'path=#{current_path}' --update-crontab #{fetch(:application)}"
    end
  end
end