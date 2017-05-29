desc "Upload .env file."
 task :upload_env do

   fetch(:infrastructures).each do |key,value|
     on roles(value[:role]) do
       upload! StringIO.new(File.read("#{value[:env]}")), "#{shared_path}/.env"
     end
   end

   run_locally do
      # Cleanup assets temp cache directory as .env file may have changed (assets may depend on .env)
      execute :rm, "-rf tmp/cache/assets/#{fetch(:rails_env)}"
   end
 end
