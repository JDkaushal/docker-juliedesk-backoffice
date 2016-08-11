desc "Upload resque scripts (start & stop)."
 task :upload_resque_scripts do
   on roles(:worker) do
     upload! StringIO.new(File.read("script/start_resque.sh")), "#{shared_path}/script/start_resque.sh"
     upload! StringIO.new(File.read("script/stop_resque.sh")), "#{shared_path}/script/stop_resque.sh"
   end
 end