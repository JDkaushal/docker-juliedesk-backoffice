desc "Upload .env file."
 task :upload_env do

   fetch(:infrastructures).each do |key,value|
     on roles(value[:role]) do
       # Keep last .env files versions
       execute "(test -f \"#{shared_path}/.env.4\" && rm #{shared_path}/.env.4) || echo \"nothing to do, no .env.4 to remove\""
       execute "(test -f \"#{shared_path}/.env.3\" && mv #{shared_path}/.env.3 #{shared_path}/.env.4) || echo \"nothing to do, no .env.3 to backup\""
       execute "(test -f \"#{shared_path}/.env.2\" && mv #{shared_path}/.env.2 #{shared_path}/.env.3) || echo \"nothing to do, no .env.2 to backup\""
       execute "(test -f \"#{shared_path}/.env.1\" && mv #{shared_path}/.env.1 #{shared_path}/.env.2) || echo \"nothing to do, no .env.1 to backup\""
       execute "cp #{shared_path}/.env #{shared_path}/.env.1"
       
       upload! StringIO.new(File.read("#{value[:env]}")), "#{shared_path}/.env"
     end
   end

   run_locally do
      # Cleanup assets temp cache directory as .env file may have changed (assets may depend on .env)
      execute :rm, "-rf tmp/cache/assets/#{fetch(:rails_env)}"
   end
 end
