desc "Upload database.yml file."
 task :upload_database_config do

   fetch(:infrastructures).each do |key,value|
     on roles(value[:role]) do
       upload! StringIO.new(File.read("config/#{value[:db]}")), "#{shared_path}/config/database.yml"
     end
   end
   
 end
