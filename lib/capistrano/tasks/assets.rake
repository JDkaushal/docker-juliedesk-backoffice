# lib/capistrano/tasks/assets.rake
#
# Override of assets compilation to leverage compilation on the deployer
# This task is compatible with "classic" parallel deployment and sequential deployment


# Remove actual precompile task
Rake::Task['deploy:assets:precompile'].clear
Rake::Task['deploy:cleanup_assets'].clear

namespace :deploy do

  task :local_cleanup_assets do
    run_locally do
      with rails_env: fetch(:rails_env), rails_groups: fetch(:rails_assets_groups) do

        assets_directory = fetch(:assets_dir, "assets")

        fetch(:infrastructures).each do |key,value|
          # Cleanup
          execute :rake, "'assets:clean[#{fetch(:keep_assets)}]'"

          roles(fetch(:assets_roles)).each do |server|
            server.roles.each do |role|
               # Support ROLE Env filtering
               if (ENV['ROLES']).nil? || /#{role}/.match(ENV['ROLES'])
                 if role == value[:role]
                    execute "rsync -av --delete ./public/"+assets_directory.to_s+"/ #{server.user}@#{server.hostname}:#{release_path}/public/"+assets_directory.to_s+"/"
                 end
               end
            end
          end
        end


     end
    end
  end

  if (ENV['deploy_sequence']).nil?
    # Override Standard Deploy Case
    task :cleanup_assets do
      invoke 'deploy:local_cleanup_assets'
    end
  end

  namespace :assets do
    desc 'Precompile assets locally and then rsync to remote servers'

    # Local precompile tasks
    # Called directly in sequential mode
    task :local_precompile do

      run_locally do
        with rails_env: fetch(:rails_env), rails_groups: fetch(:rails_assets_groups) do

          assets_directories = fetch(:assets_dirs, %w"assets packs")

          fetch(:infrastructures).each do |key,value|
            # Compilation
            execute "RAILS_ENV=\"#{fetch(:rails_env)}\" ENV_FILE=\"#{value[:env]}\" rake assets:precompile"

            roles(fetch(:assets_roles)).each do |server|
              server.roles.each do |role|
                # Support ROLE Env filtering
                if (ENV['ROLES']).nil? || /#{value[:role]}/.match(ENV['ROLES'])
                  if role == value[:role]
                    assets_directories.each do |assets_directory|
                      execute "rsync -av ./public/"+assets_directory.to_s+"/ #{server.user}@#{server.hostname}:#{release_path}/public/"+assets_directory.to_s+"/"
                    end
                  end
                end
              end
            end

          end

        end
      end

    end

    if (ENV['deploy_sequence']).nil?
      # Override Standard Deploy Case
      task :precompile do
        invoke 'deploy:assets:local_precompile'
      end
    end
  end
end
