desc "Upload .env file."
 task :upload_env do

   fetch(:infrastructures).each do |key,value|
     on roles(value[:role]) do
       upload! StringIO.new(File.read("#{value[:env]}")), "#{shared_path}/.env"
     end
   end

 end
