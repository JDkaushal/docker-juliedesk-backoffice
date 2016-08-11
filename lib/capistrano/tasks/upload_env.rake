desc "Upload .env file."
 task :upload_env do
   on roles(:all) do
     upload! StringIO.new(File.read(".env")), "#{shared_path}/.env"
   end
 end