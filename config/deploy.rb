# config valid only for current version of Capistrano
lock '3.6.0'

set :application, 'juliedesk_backoffice'
set :repo_url, "deployer@#{ENV['DEPLOY_SERVER_IP']}:apps/juliedesk-backoffice"
set :branch, 'master'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/appuser/apps/juliedesk_backoffice'

set :scm, :git
set :user, 'appuser'
set :assets_roles, [:web, :app, :test]

set :linked_dirs, %w{log tmp/pids script}
set :linked_files, %w{config/database.yml .env}
set :rvm_ruby_version, '2.2.0'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 2

set :keep_assets, 1

# Classic deploy. These tasks are overidden in case of deploy_sequence task so they are deactivated
# if we are in the deploy_sequence case
if (ENV['deploy_sequence']).nil?
  after :deploy, :restart_server
  after :deploy, :update_crontab
  after :deploy, :run_resque
end

after :deploy_sequence, :restart_server
after :deploy_sequence, :update_crontab
after :deploy_sequence, :run_resque