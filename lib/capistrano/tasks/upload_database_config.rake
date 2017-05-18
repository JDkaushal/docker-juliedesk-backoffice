desc "Upload database.yml file."
 task :upload_database_config do
   on roles(:ey) do
     upload! StringIO.new(File.read("config/database-ey.yml")), "#{shared_path}/config/database.yml"
   end

   on roles(:jd) do
     upload! StringIO.new(File.read("config/database.yml")), "#{shared_path}/config/database.yml"
   end
 end
