desc 'Restart application'
task :restart_server do
  on roles(:web), in: :sequence, wait: 5 do
    execute :touch, release_path.join('tmp/restart.txt')
  end
end