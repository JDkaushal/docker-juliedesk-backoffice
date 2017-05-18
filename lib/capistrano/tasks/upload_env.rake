desc "Upload .env file."
 task :upload_env do
   on roles(:jd) do
     upload! StringIO.new(File.read(".env")), "#{shared_path}/.env"
   end
   on roles(:ey) do
     upload! StringIO.new(File.read("ey.env")), "#{shared_path}/.env"
   end
 end
