desc "Specify access rights"
task :set_acl do
  on roles(:all), in: :sequence, wait: 5 do
     # Code files
     execute "find " + release_path.to_s + "/ -type f -exec chmod 0640 {} \\;"
     execute "find " + release_path.to_s + "/ -type d -exec chmod 0750 {} \\;"
     
     # Tmp (SGID to allow creation of file by server)
     execute "chmod 2770 " + release_path.to_s + "/tmp"

     # Shared
     execute "(test -d \"" + shared_path.to_s + "/public\" && find " + shared_path.to_s + "/public -type f -exec chmod 0640 {} \\;) || echo \"nothing to do\""
     execute "(test -d \"" + shared_path.to_s + "/public\" && find " + shared_path.to_s + "/public -type d -exec chmod 0750 {} \\;) || echo \"nothing to do\""

     # Config
     execute "(test -d \"" + shared_path.to_s + "/config\" && find " + shared_path.to_s + "/config -type f -exec chmod 0640 {} \\;) || echo \"nothing to do\""
     execute "(test -d \"" + shared_path.to_s + "/config\" && find " + shared_path.to_s + "/config -type d -exec chmod 0750 {} \\;) || echo \"nothing to do\""

     # .env
     execute "chmod 0640 " + shared_path.to_s + "/.env"

  end
end