TicketService.configure do |config|
  config.api_url     = ENV['JIRA_API_URL']
  config.api_user    = ENV['JIRA_API_USER']
  config.api_key     = ENV['JIRA_API_KEY']
  config.api_version = 2
  config.project_id  = ENV['JIRA_DEFAULT_PROJECT_ID']
end

