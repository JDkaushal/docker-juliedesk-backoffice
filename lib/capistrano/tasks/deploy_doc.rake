desc "Deploy doc"
task :deploy_doc do
  run_locally do
    execute "../doc/deploy_doc juliedesk-backoffice"
  end
end