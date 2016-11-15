

namespace :deploy do
  desc "HOWTO"
  task :howto do

    def colorize(text, color=32)
      "\033[#{color}m#{text}\033[0m"
    end

    run_locally do
        puts colorize "***** Edit environment variable(s) *****"
        puts "$ vi .env"
        puts "Then Add your variable : CONSTANT_NAME=constantvalue"
        puts "\n"
        puts "$ bundle exec cap production upload_env"
        puts "$ bundle exec cap production restart_server"
        puts "$ bundle exec cap production run_resque"
        puts "\n\n"

        puts colorize "***** Execute pending database migration(s) *****"
        puts "Make sure the code works fine after the migration and before the deployment to avoid any error"
        puts "$ bundle exec rake db:migrate RAILS_ENV=production"
        puts "\n\n"

        puts colorize "***** Deploy the code *****"
        puts "$ bundle exec cap production deploy"
        puts "\n"
        puts "- tasker(s) only -"
        puts "$ ROLES=tasker bundle exec cap production deploy"
        puts "\n"
        puts "- worker(s) only -"
        puts "$ ROLES=worker bundle exec cap production deploy"
        puts "\n"
        puts "- web only -"
        puts "$ ROLES=web bundle exec cap production deploy"
        puts "\n\n"

        puts colorize "***** Restart web servers *****"
        puts "$ bundle exec cap production restart_server"
        puts "\n\n"

        puts colorize "***** Restart workers *****"
        puts "$ bundle exec cap production run_resque"
        puts "\n\n"

        puts colorize "***** Update resque scripts *****"
        puts "$ bundle exec cap production upload_resque_scripts"
        puts "$ bundle exec cap production run_resque"
        puts "\n\n"

        puts colorize "***** Update database config *****"
        puts "$ bundle exec cap production upload_database_config"
        puts "$ bundle exec cap production restart_server"
        puts "$ bundle exec cap production run_resque"
        puts "\n\n"
      end
  end
end