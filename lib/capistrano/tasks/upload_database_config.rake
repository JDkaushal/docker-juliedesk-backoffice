desc "Upload database.yml file."
 task :upload_database_config do
   on roles(:all) do
     upload! StringIO.new(File.read("config/database.yml")), "#{shared_path}/config/database.yml"
   end
 end