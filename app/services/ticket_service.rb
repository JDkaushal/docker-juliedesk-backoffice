module TicketService
  class << self
    attr_accessor :config
  end

  class DuplicateTicket < StandardError ; end


  def self.configure
    self.config ||= JiraConfiguration.new
    yield(config)
  end

  def self.create_ticket(summary, description, options = {})
    labels = options.fetch(:tags, [])
    data = {
        summary: summary,
        description: description,
        labels: labels
    }
    Jira.new(jira_options).create_ticket(Jira::TASK_ISSUE, data)

  rescue Jira::DuplicateTicket => e
    raise DuplicateTicket.new(e)
  end

  def self.ticket_exist?(summary)
    Jira.new(jira_options).duplicate?(summary: summary)
  end

  def self.jira_options
    {
        api_url:      self.config.api_url,
        api_user:     self.config.api_user,
        api_key:      self.config.api_key,
        api_version:  self.config.api_version,
        project_id:   self.config.project_id
    }
  end

  class JiraConfiguration
    attr_accessor :api_url, :api_user, :api_key, :api_version, :project_id

    def intialize
    end
  end

end